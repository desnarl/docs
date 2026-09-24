---
sidebar_position: 6
title: Troubleshooting
---

# Troubleshooting & recovery

This page covers the recovery scenarios that are actually documented today. A stuck license check-in past its grace period is not one of them — that mechanic isn't built yet, and its own grace-period length isn't decided, so recovery guidance for it would be a guess rather than a documented procedure. This section will be extended once that ships; until then, treat a license-related failure as outside its scope.

## SQLite corruption

`.crossrepo-graph/graph.db` is a single SQLite file; on-disk corruption (a killed process mid-write with WAL not yet checkpointed, a bad disk sector, a partial volume-mount copy) surfaces as SQLite's own error on next open, most commonly `database disk image is malformed`.

There is no in-place repair path for a corrupted `.db` file. Recovery is to restore your most recent checkpointed backup (see [Self-hosted deployment → Storage & upgrades](./self-hosted/deployment.md#storage--upgrades) for what a valid backup actually requires) and let this instance's own migration/reindex path bring it back up to date on next startup. There is currently no automated corruption *detection* separate from the open failing outright.

## Failed ingestion mid-run

A scheduled pull can fail for a few distinct, categorized reasons rather than one generic error:

- **`auth-failure`** — the configured deploy key/PAT was rejected (expired, revoked, or under-scoped). Fix: rotate or re-scope the credential in your own infrastructure and restart ingestion — no data is lost, the next scheduled poll picks up where the last successful one left off.
- **`network-error`** — the request to the git remote failed outright, or returned a non-2xx status that wasn't an auth rejection. Fix: check your own network path to the remote; this isn't something this instance can recover from on its own.
- **`host-rejected`** / **`redirect-rejected`** — the configured remote URL (or a redirect it returned) isn't `github.com`/`api.github.com` over `https`. This is a configuration error, not a transient failure — correct the configured remote URL rather than retrying.

None of these leave the local clone at `.crossrepo-graph/repos/<repo-name>/` in a state that needs manual cleanup: a failed fetch simply leaves the prior successful clone in place, unindexed until the next successful poll.

## CI check reports "could not verify"

This is the network-endpoint-backed check a *consuming* repo runs in its own CI (see [Self-hosted deployment → Network-queryable endpoint](./self-hosted/deployment.md#network-queryable-endpoint-for-ci)). When the whole check can't run, it reports a distinct, named reason rather than silently reading as "no consumers affected":

- **`connection-failed`** — the CI runner couldn't reach this instance's network endpoint at all (DNS failure, connection refused, timeout). Fix: confirm the CI runner is genuinely inside the same network as this instance (a self-hosted runner, never a GitHub-hosted one) and that the endpoint URL in the consuming repo's workflow points at the right host/port.
- **`unauthorized`** — the request reached this instance but its bearer token was rejected (missing, malformed, or since rotated on this instance without the consuming repo's own CI secret being updated to match). Fix: rotate/re-issue the token and update the token secret in every consuming repo's own CI — a shared token distributed to multiple repos means updating all of them, not just one.
- **`rate-limited`** — this instance's own rate limiter has locked out the caller after repeated invalid-token attempts. Fix: wait out the configured lockout window, then confirm the token is actually correct before retrying.

None of these three ever cause the check to report a false "no consumers affected" — a batch that can't run at all is always reported as unreachable, distinct from a completed batch.

## Getting help

Support is an **in-portal ticket system** — file a ticket from inside the license portal at [desnarl.com](https://desnarl.com), once you've created an account and signed in. That system is not live yet; this page will link directly to it once it ships.

**There is no email support and no public Discord (or other community) support channel, for any tier — that's a deliberate, permanent decision, not a temporary gap.** Don't file an issue on this repo, or reach out via any other channel, expecting a support response.

When the in-portal ticket system is available: **never share your license key or your deploy key/PAT in a support request.** If you need to demonstrate a problem, share only the output of your instance's self-diagnostic report (license status, staleness, version) — never the raw credential. Likewise, never send `.crossrepo-graph/graph.db` or any indexed repo content off your own network for debugging — Desnarl's entire data-custody guarantee depends on that content never leaving your infrastructure, and a support request is not an exception to it.
