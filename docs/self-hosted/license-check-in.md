---
sidebar_position: 4
title: License check-in
---

# License check-in

The license check-in is a small, periodic call from your Desnarl instance to the license portal. It lets the portal tell the instance whether its license key is in good standing. This page documents the whole exchange so you can audit exactly what leaves your network.

:::note[An honour check, not DRM]
The license check is an honour check, not copy protection. It is not a way to stop someone who controls the machine. The state file it keeps is unsigned, and the check can be switched off with a documented setting (see [Settings](#settings)). This matches the position in the [licensing FAQ](../licensing-pricing-faq.md): licensing is self-attested, not enforced or verified. Nothing in the check-in confirms whether your use is commercial or non-commercial.
:::

## What is sent

Each check-in sends the license key, a bucketed repo count and the tool version, and nothing else.

It never sends repo content, file paths, repo names, symbol names, source code or queries.

The request is an HTTPS `POST` with a JSON body. The key is in the body, never in the URL or query string, so it does not appear in URLs recorded by proxies or access logs.

```http
POST https://desnarl.com/api/license/check-in
Content-Type: application/json

{
  "key": "crg_00000000000000000000000000000000",
  "repoBucket": "6-20",
  "toolVersion": "1.4.2"
}
```

The default endpoint is `https://desnarl.com/api/license/check-in`. The client uses exactly this path, makes no other request, and refuses redirects. It waits up to 5 seconds for an answer and reads at most 4 KB of it. You can [switch the check-in off or point it at another host](#settings).

The body has exactly these three fields. A request with any other field is rejected.

| Field | Type | Rules |
|---|---|---|
| `key` | string | Your license key. The instance accepts `crg_` followed by 32 lowercase letters or digits, and keys are issued with hexadecimal characters (`0`-`9` and `a`-`f`). The portal accepts only the hexadecimal form, so a key that passes the instance's local check but is not hexadecimal is rejected by the portal as a malformed request, which the instance treats as no answer. |
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

- an HTTP `400`, `429` or `5xx`, or any status other than `200`;
- a network error or timeout;
- a response that is not valid JSON;
- an unknown `contractVersion`, `state` or `reason`;
- a `grace` answer whose `daysRemaining` is outside 0 to 7.

A "no answer" never blocks by itself. It only adds to the silence clock described next, so a failure or outage on the license server cannot block you on its own account.

## Cadence and offline behaviour

With a missing or malformed key the server does not check in at all: it serves only `crossrepo_license_required` and makes no network call. With a valid-looking key, the instance checks in once when it starts, then roughly daily (with random jitter, so a fleet does not call in at once). It never calls more often than hourly. A check-in never delays the server starting or answering a query.

Two separate counters decide what you see. They are counted independently.

**Silence: no authenticated answer.** An *authenticated answer* is a complete, valid `200` response from the endpoint. Anything else is "no answer". The silence clock runs from the last authenticated answer, or from the first attempt if there has never been one. Any authenticated answer resets it.

| Days with no authenticated answer | What happens |
|---|---|
| 0 to 6 | Nothing. The tool works normally, with no notice. |
| 7 to 29 | The tool keeps working and shows a non-blocking **unverified** notice. |
| 30 or more | The tool blocks locally. |

**Payment: an authenticated `grace` answer.** If the portal answers `grace`, you have 7 days from the payment failure, counted down from the time your instance received the answer (the server's clock is never used for counting). The tool keeps working and shows a payment-problem notice. When the portal then answers `blocked` with `payment_overdue`, the tool blocks.

**Blocked answers.** An authenticated `blocked` answer with a known `reason` blocks at once, whatever the silence clock says. The block lasts until the next authenticated answer that is not `blocked`. A blocked instance re-checks about hourly, so a customer who has just paid is not kept out for up to a day.

If the machine's clock is set back, the client counts that as no time elapsed rather than as extra time.

## Settings

These are environment variables, set in the same `env` block as your license key.

| Variable | Effect |
|---|---|
| `CROSSREPOGRAPH_DISABLE_LICENSE_CHECKIN` | Set to `true` (any case) or `1` to switch the check-in off. Nothing is sent, no `checkin-state.json` is written, no notices appear and nothing blocks. It wins over every other setting. This is the supported setting for installs with no outbound access; pair it with the registry-resolution setting as described in [Configuration](./configuration.md#running-without-outbound-access). Without the check-in, the portal cannot tell the instance about a payment problem or a revoked key. Any other value leaves the check-in on. |
| `CROSSREPOGRAPH_CHECKIN_URL` | Replaces the default endpoint, for a staging host or a test. It must be `https`, use exactly the path `/api/license/check-in`, and carry no credentials, query string or fragment. An invalid value switches the check-in off, prints one fixed line on stderr that does not repeat the value, and **never falls back to the default**. |
| `CROSSREPOGRAPH_CHECKIN_ALLOW_INSECURE_LOOPBACK` | Set to `true` (any case) or `1` to let `CROSSREPOGRAPH_CHECKIN_URL` use plain `http`, and only when its host is `127.0.0.1`, `localhost` or `[::1]`. It exists for testing against a server on the same machine. It does nothing without `CROSSREPOGRAPH_CHECKIN_URL`, and every other rule for that URL still applies. Any other value leaves it off. |

## What stays on your machine

The check-in keeps one file in your [state directory](./state-directory.md), `checkin-state.json`. It is versioned and holds:

- a SHA-256 hash of your license key, never the key itself;
- the time of the first attempt and of the last authenticated answer;
- the last authenticated answer: its state, the `reason` or `daysRemaining` if it had one, and when it arrived.

The file is not signed. A time stored in it that is more than 24 hours ahead of your machine's clock is treated as tampering and ignored: a future first-attempt time or a future time on the last answer discards the whole stored history, as if the file did not exist, and a future last-success time is dropped, so the silence clock runs from the first attempt as if no authenticated answer had ever arrived.

It is safe to delete, and the next check-in recreates it. Deleting it also restarts the 30-day silence clock, because the file holds the times the clock runs from (the last authenticated answer, or the first attempt). If it cannot be written, the tool keeps working. A block the portal has answered comes back at the next check-in.

## How notices appear

The server cannot push anything to your AI client, and many hosts do not show stderr. So notices travel in the tool results themselves:

- A short, fixed line is placed at the start of a tool's result. It is added to results only. It never goes in the MCP server `instructions`, which hosts cache.
- The **unverified** notice appears once per session.
- The **payment-problem** notice appears once per session, and again at most every six hours in the final day of the grace period.
- After a block, a tool call returns a single fixed message instead of running. The message depends on the `reason` (for example, the payment-overdue message), or is the 30-day silence message. The list of tools does not change.

Every word is fixed text inside your instance, chosen by state or reason code. The only value ever filled in is a whole number of days. The server sends no text, so nothing it returns can put its own words in front of you or your AI client.

## If you are blocked or see an unverified notice

- **Unverified notice:** your instance has not reached the portal for 7 days or more. Nothing is broken and the tool keeps working. Connect the machine to the internet (or allow outbound HTTPS to `desnarl.com`) and the next check clears it.
- **Blocked for 30 days of silence:** connect to the internet. The tool resumes within an hour of the next check, with no restart needed.
- **Blocked for `payment_overdue` or `canceled`:** bring the payment up to date, or start a new subscription. It resumes within an hour of the next check.
- **`revoked` or `unknown_key`:** check the value of `CROSSREPOGRAPH_LICENSE_KEY`. A revoked key needs a replacement from the vendor.
- **No outbound access at all:** use `CROSSREPOGRAPH_DISABLE_LICENSE_CHECKIN`, above.

If you believe a block is wrong, see [Getting help](../troubleshooting.md#getting-help). The in-portal ticket system is not live yet, and there is no email or Discord support. Never put your license key in a ticket.

### Accepted risk

A TLS-intercepting proxy that your machine trusts can answer `blocked`, and so block that machine until the next genuine answer. The client cannot tell such a proxy from the portal.

## What the server keeps

- The latest check-in for a license is stored in a single record that is overwritten each time. There is no history of check-ins.
- The rate limiter stores only a keyed hash of the requesting IP address and a keyed hash of the key, for 1 day.
- Web proxy and application logs may still contain raw IP addresses under the operator's ordinary log retention. This page does not claim that IP addresses are not logged. The retention period will be stated in the privacy notice.

None of this changes the wider position described in the deployment guide: repo content never leaves your infrastructure, and the GDPR exposure is reduced to standard SaaS-signup scope, not eliminated.
