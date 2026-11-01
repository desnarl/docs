---
sidebar_position: 4
title: License check-in
---

# License check-in

:::caution Planned contract, not yet shipped
This page describes the **planned v1 contract** for Desnarl's license check-in. The check-in is **not yet part of the released product**: no released instance makes this call today, and the details below (including the endpoint address and the exact bucket spellings) may still change before it ships. It is published so that a security reviewer can see exactly what the call will carry before it exists. The [deployment guide](./deployment.md) lists the check-in as "Not yet shipped" and will be updated when it is.
:::

The license check-in is a small, periodic call from your Desnarl instance to the license portal. It lets the portal tell the instance whether its license key is in good standing. This page documents the whole exchange so you can audit exactly what leaves your network.

## What is sent

Each check-in sends the license key, a bucketed repo count and the tool version, and nothing else.

It never sends repo content, file paths, repo names, symbol names, source code or queries.

The request is an HTTPS `POST` with a JSON body. The key is in the body, never in the URL or query string, so it does not appear in URLs recorded by proxies or access logs.

```http
POST https://<license-portal-host>/api/license/...
Content-Type: application/json

{
  "key": "crg_00000000000000000000000000000000",
  "repoBucket": "6-20",
  "toolVersion": "1.4.2"
}
```

:::note Endpoint address not final
`https://<license-portal-host>/api/license/...` is a placeholder. The real host and path will be published here when the server side is finished.
:::

The body has exactly these three fields. A request with any other field is rejected.

| Field | Type | Rules |
|---|---|---|
| `key` | string | Your license key: `crg_` followed by 32 lowercase hexadecimal characters. |
| `repoBucket` | string | One of a closed set: `"1-5"`, `"6-20"`, `"21-100"`, `"100+"`. An exact repo count is rejected. |
| `toolVersion` | string | Up to 64 characters: letters, digits, `.`, `+` and `-`, starting with a letter or digit. |

The request must use `Content-Type: application/json`, and the body limit is about 1 KB.

## What the server returns

The response is a fixed schema of a state and a number. It never contains message text. All wording shown to you is rendered locally by your instance from fixed copy keyed by the state code. A compromised or spoofed endpoint therefore has no channel through which to put its own words in front of you or your AI client.

```json
{
  "contractVersion": 1,
  "serverTime": "2026-11-01T09:30:00Z",
  "state": "grace",
  "daysRemaining": 5
}
```

| Field | Meaning |
|---|---|
| `contractVersion` | Integer, currently `1`. |
| `serverTime` | The server's clock, so the instance can account for clock skew. |
| `state` | One of `ok`, `grace` or `blocked`. |
| `daysRemaining` | Present with `grace` only: an integer from 1 to 7. |
| `reason` | Present with `blocked` only: one of `payment_overdue`, `canceled`, `revoked` or `unknown_key`. |

## What each state means

| State | When it applies |
|---|---|
| `ok` | The license is in good standing. This covers active paid subscriptions, free noncommercial ($0) subscriptions and trials. |
| `grace` | A payment has failed. You have 7 days from the failure, and `daysRemaining` counts down from there. The tool keeps working throughout. |
| `blocked` | Access is blocked, with a `reason` (below). A payment-failure block starts exactly when the 7 days end. |

| `reason` | Meaning |
|---|---|
| `payment_overdue` | The 7-day payment grace has ended without payment. |
| `canceled` | The subscription was canceled. |
| `revoked` | The license has been revoked. |
| `unknown_key` | The key is not recognised, or the account has no subscription yet. |

`unknown_key` deliberately covers both "no such key" and "account with no subscription yet". The two are answered identically so the endpoint never reveals which keys exist.

If you see `unknown_key` or `revoked` and believe it is wrong, file a ticket in the license portal. The in-portal ticket system is the only support channel, and it is [not live yet](../troubleshooting.md#getting-help). There is no email or Discord support. Never put your license key in a ticket.

## HTTP behaviour, and failing open

| Situation | Response |
|---|---|
| A well-formed lookup, whatever the answer | `200` with the one body shape above. |
| A malformed request | `400` with `{"error":"invalid_request"}`. |
| Rate limited | `429` with a `Retry-After` header. |
| A server error | `5xx`. An error is never reported as a `200` state. |

Responses carry `Cache-Control: no-store`.

The client treats each of these as **no answer**, never as `blocked`:

- an HTTP `400`, `429` or `5xx`;
- a network error or timeout;
- a response that is not JSON;
- an unknown `contractVersion`;
- an unknown `state`;
- an unknown `reason`.

A "no answer" counts toward the offline grace below. A failure or outage on the license server can therefore never block you by itself.

## Cadence and offline behaviour

- **Normal cadence:** the instance checks in daily.
- **Offline grace:** if the instance cannot get a successful check-in, it keeps working for 7 days. After that the tool degrades with a hard block. This is separate from the 7-day payment grace above: the two are counted independently.
- **After a block:** a blocked instance re-checks on startup and hourly, so a customer who has just paid is not kept out for up to a day.
- **Air-gapped installs:** the planned design includes an explicit opt-out for installs with no outbound access, in the same spirit as the registry-resolution setting described in the [deployment guide](./deployment.md#registry-resolved-version-skew-checks). The setting name and its exact effect will be documented here when the client ships.

## What the server keeps

- The latest check-in for a license is stored in a single record that is overwritten each time. There is no history of check-ins.
- The rate limiter stores only a keyed hash of the requesting IP address and a keyed hash of the key, for 1 day.
- Web proxy and application logs may still contain raw IP addresses under the operator's ordinary log retention. This page does not claim that IP addresses are not logged. The retention period will be stated in the privacy notice.

None of this changes the wider position described in the deployment guide: repo content never leaves your infrastructure, and the GDPR exposure is reduced to standard SaaS-signup scope, not eliminated.
