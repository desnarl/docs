---
sidebar_position: 1
title: Deployment guide
---

# Self-hosted deployment guide

Desnarl is designed so that repo content — source, migrations, queries — never leaves your own infrastructure. Storage and compute both run where you run them. That's a real, structural property of the architecture, not something bolted on: the operator never holds your repo content at all.

That claim is scoped narrowly to repo *content*, though, and it's worth being precise about the rest of what this instance does over the network:

:::info[What actually leaves your network]
Desnarl makes network calls in four places, allowlisted by design and kept minimal:

| Call | Destination | Status |
|---|---|---|
| Registry-resolved version-skew checks | `registry.npmjs.org` | Live in v0.2.0; can be switched off |
| [License check-in](./license-check-in.md) | `desnarl.com` (the license portal) | Live in v0.2.0; can be switched off |
| Git ingestion (polling your repos) | `github.com` / `api.github.com` | Planned, not part of v0.2.0 |
| Staleness alert | a webhook you configure | Planned, not part of v0.2.0 |

Two of the four are live today: registry lookups and the license check-in. Registry lookups send only a package name. The license check-in sends your license key, a repo-count range and the tool version about once a day. You can switch either off with `CROSSREPOGRAPH_DISABLE_REGISTRY_RESOLUTION` and `CROSSREPOGRAPH_DISABLE_LICENSE_CHECKIN`; see [Configuration](./configuration.md#running-without-outbound-access). The other two are not part of v0.2.0, so v0.2.0 never contacts GitHub or a webhook.

None of the live calls ever transmits repo content, file paths, or source code — only what each section below documents explicitly (a package name, or a license key, repo-count range and tool version). This is **"GDPR exposure reduced to standard SaaS-signup scope, not eliminated"** — account creation and the license check-in are still personal/business data processing under GDPR's general scope, even though repo content itself never leaves your infrastructure.
:::

## Planned, not in v0.2.0

Reading repos from a remote host, a network endpoint for CI, and alerting when a repo has not been re-read are planned. v0.2.0 does none of them: it reads only the repos checked out on disk under your workspace root, runs as a local stdio server, opens no network port, and sends no alert. This page will describe them when they ship.

## Registry-resolved version-skew checks

`src/registry/` queries the public npm registry (`registry.npmjs.org` — the only host it will ever contact for this) to compare a consumer's declared version range against what's actually published, when no lockfile is available to resolve it locally. Only the package/scope name being looked up leaves your machine — never repo content, never file paths, never source code.

**Disabling it entirely:** set `CROSSREPOGRAPH_DISABLE_REGISTRY_RESOLUTION=true` (or `1`) to turn off registry resolution, for instances with no outbound access. With this set, version-skew checks fall back to declared-range-only comparison and report this explicitly, distinct from a failed/unreachable lookup — never a silent gap.

## Storage & upgrades

This instance keeps its graph state in a single SQLite file, `graph.db`, in your [state directory](./state-directory.md), in WAL mode.

**Backing it up:** because WAL mode leaves recent transactions in a separate `-wal` file, a valid backup is **not** a raw `cp graph.db`. Either checkpoint first, or copy the `.db`/`-wal`/`-shm` files together as one set. A `.db`-only copy taken while WAL is active can silently miss recent writes.

**Upgrading:** on every version bump, this instance runs any pending schema migrations automatically on next startup, inside a single transaction — a migration failing partway rolls back cleanly, leaving the database exactly as it was before the upgrade attempt. If the on-disk schema version is ever newer than a given build knows about (e.g. after rolling an instance back to an older release), startup fails fast with a clear error rather than silently misinterpreting a schema it doesn't recognize.

**Rollback:** since a failed migration already rolls back automatically, "rolling back" in practice means reverting to the prior build. Restore your last checkpointed backup if you suspect any drift, then run the prior version against it. This instance does not tell you when a newer release exists. Whether one exists is left to your own vigilance for now. The [license check-in](./license-check-in.md) reports only the standing of your license and does not report whether an update is available.

## Next

See [What Desnarl keeps on disk](./state-directory.md) for where the state directory is and what each file in it is.

See [The savings report](./savings-report.md) for where the per-workspace report lives and how to read it.

See [Configuration](./configuration.md) for every setting, and [Troubleshooting](../troubleshooting.md) for recovery from SQLite corruption and the other documented recovery scenarios.
