---
sidebar_position: 1
title: Deployment guide
---

# Self-hosted deployment guide

Desnarl is designed so that repo content — source, migrations, queries — never leaves your own infrastructure. Storage and compute both run where you run them. That's a real, structural property of the architecture, not something bolted on: the operator never holds your repo content at all.

That claim is scoped narrowly to repo *content*, though, and it's worth being precise about the rest of what this instance does over the network:

:::info What actually leaves your network
Desnarl makes network calls in four places, allowlisted by design and kept minimal:

| Call | Destination | Status |
|---|---|---|
| Ingestion (polling your own repos) | `github.com` / `api.github.com` | Shipped |
| Registry-resolved version-skew checks | `registry.npmjs.org` | Shipped |
| Staleness-monitoring alert | your configured Discord/Slack webhook | Built, not yet active |
| License check-in | the license portal | Not yet shipped |

Two of the four are live today: ingestion and registry lookups. The staleness alert's code is built, but no released instance starts it yet, so no alert is sent. The license check-in is designed and not part of the product yet.

None of these ever transmit repo content, file paths, or source code — only what each section below documents explicitly (a package name, a webhook post, a license identifier). This is **"GDPR exposure reduced to standard SaaS-signup scope, not eliminated"** — account creation and any future license check-in are still personal/business data processing under GDPR's general scope, even though repo content itself never leaves your infrastructure.
:::

## Ingestion authentication

`src/ingestion/` authenticates this instance's scheduled polling of your own repos using a deploy key or fine-grained personal access token (PAT), scoped read-only to the repos it needs. The credential is read from an environment variable or mounted secret file at process start and never persisted anywhere — not to the SQLite store, not to the query log, not to any diagnostic output. Every request goes only to `github.com`/`api.github.com`, https-only, checked before the request goes out and again if the response redirects.

**Credential custody.** The deploy key/PAT is a credential you hold — the operator never sees or stores it. Anyone holding it can read the repos it's scoped to; there's no separate authentication layer beyond possessing the value itself.

- Don't commit it to source control or paste it into a public issue/PR.
- If it leaks, revoke it immediately in GitHub's own UI (Settings → Developer settings → Personal access tokens, or the deploy-key list on the specific repo) and issue a new one — the old value stops working the moment it's revoked.
- No fixed rotation cadence is enforced by the tool itself; rotate on a schedule matching your own organization's existing credential-rotation policy, or at minimum whenever team membership changes.

## Network-queryable endpoint (for CI)

`src/mcp/network-*.ts` extends this instance's stdio MCP server with a Streamable HTTP transport, so a CI job can query `crossrepo_impact`/`crossrepo_consumers` over the network instead of running standalone. No other tool is exposed this way — the full MCP surface otherwise stays stdio-only.

**Reachability: your own self-hosted GitHub Actions runner, never the public internet.** This instance should never be exposed to a GitHub-hosted runner or any other internet-facing caller — only a runner inside your own network should be able to reach it.

**TLS is your own responsibility, not this process's.** The endpoint speaks plain HTTP — put it behind your own reverse proxy (or your runner network's own TLS termination) before treating the bearer token below as safely transmittable. A token sent over plaintext HTTP is trivially sniffable by anything else on that network path.

**Credential custody.** The network endpoint's API token is the same credential class as the ingestion deploy key/PAT above: read from an environment variable or mounted secret at process start, compared in constant time, never persisted anywhere.

- Don't commit it to source control or paste it into a public issue/PR.
- If it leaks, generate a new one and update wherever your CI reads it from — the token is re-read fresh on every request, so rotation takes effect immediately, with no restart required.
- No fixed rotation cadence is enforced by the tool itself; rotate on a schedule matching your own organization's existing credential-rotation policy, or at minimum whenever a CI runner's own access changes.

Repeated invalid-token attempts are rate-limited, locking out a caller for a configurable window after a configurable number of failures — a distinct `429` response, separate from the `401` an individual bad request gets.

## Staleness monitoring

:::caution Built, not yet active
The monitoring code exists and is tested, but no released instance starts it. Configuring a Discord or Slack webhook today will not send anything. This section describes how alerting will work once it is switched on.
:::

`src/monitoring/` watches how long it's been since each repo in your instance last reindexed successfully, and posts an alert to a Discord webhook, a Slack webhook, or both, when a repo crosses a staleness threshold (24 hours by default). Each channel is independently optional and off by default.

**Setting up Discord:** create an incoming webhook in your Discord server (Server Settings → Integrations → Webhooks → New Webhook), copy the URL, and configure it as this instance's alert target. The URL is only ever validated as pointing at `discord.com`/`discordapp.com` before use.

**Setting up Slack:** create a minimal Slack App in your target workspace with an Incoming Webhook enabled, copy the webhook URL, and configure it as this instance's alert target. The URL is only ever validated as pointing at `hooks.slack.com` before use.

**Credential custody.** Both webhook URLs are bearer-style credentials — anyone holding one can post messages to that channel. Each is held entirely by you; the operator never sees or stores either.

- Don't commit either to source control or paste it into a public issue/PR.
- If a Discord webhook leaks, regenerate it from Discord's own UI. If a Slack webhook leaks, regenerate it from the Slack App's own Incoming Webhooks settings. Either way, update your instance's configuration — the old URL stops working the moment the webhook is deleted/deactivated.

:::note This is not the support channel
This webhook is an alert channel *you* configure, to a Discord or Slack workspace *you* control — it has nothing to do with getting help from Desnarl. See [Troubleshooting → Getting help](../troubleshooting.md#getting-help) for that.
:::

## Registry-resolved version-skew checks

`src/registry/` queries the public npm registry (`registry.npmjs.org` — the only host it will ever contact for this) to compare a consumer's declared version range against what's actually published, when no lockfile is available to resolve it locally. Only the package/scope name being looked up leaves your machine — never repo content, never file paths, never source code.

**Disabling it entirely:** set `CROSSREPO_GRAPH_DISABLE_REGISTRY_RESOLUTION=true` (or `1`) to turn off registry resolution for instances with no outbound egress at all. With this set, version-skew checks fall back to declared-range-only comparison and report this explicitly, distinct from a failed/unreachable lookup — never a silent gap.

## Storage & upgrades

This instance keeps its graph state in a single SQLite file, `.crossrepo-graph/graph.db`, in WAL mode.

**Backing it up:** because WAL mode leaves recent transactions in a separate `-wal` file, a valid backup is **not** a raw `cp .crossrepo-graph/graph.db`. Either checkpoint first, or copy the `.db`/`-wal`/`-shm` files together as one set. A `.db`-only copy taken while WAL is active can silently miss recent writes.

**Upgrading:** on every version bump, this instance runs any pending schema migrations automatically on next startup, inside a single transaction — a migration failing partway rolls back cleanly, leaving the database exactly as it was before the upgrade attempt. If the on-disk schema version is ever newer than a given build knows about (e.g. after rolling an instance back to an older release), startup fails fast with a clear error rather than silently misinterpreting a schema it doesn't recognize.

**Rollback:** since a failed migration already rolls back automatically, "rolling back" in practice means reverting to the prior build. Restore your last checkpointed backup if you suspect any drift, then run the prior version against it. Version-currency (whether a newer release exists) is left to your own vigilance for now — this instance doesn't check in for update notifications.

## Next

See [Troubleshooting](../troubleshooting.md) for recovery from SQLite corruption, failed ingestion, and CI check failures.
