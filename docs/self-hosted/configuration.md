---
sidebar_position: 6
title: Configuration
---

# Configuration

Desnarl is configured with environment variables, set in the `env` block of your MCP client's server entry (or with `-e` for the container). Two things are not settings: the **workspace root** is a required positional argument, and the **license key** is described on the [install page](../getting-started/install.md#license-key).

A flag that takes `true` or `1` is a **strict** match: anything else, including a typo, leaves the setting at its default.

| Variable | Default | What it does |
|---|---|---|
| `CROSSREPOGRAPH_LICENSE_KEY` | none (required) | Your license key: `crg_` followed by 32 lowercase letters or digits. Without a valid one the server exposes only `crossrepo_license_required`. |
| `CROSSREPOGRAPH_STATE_DIR` | per-workspace folder under your user-data directory; `/state` in the image | Where the cache, query log, savings report and check-in record live. Must be an absolute path, and must not be inside the workspace. See [What Desnarl keeps on disk](./state-directory.md). |
| `XDG_STATE_HOME`, `LOCALAPPDATA` | set by your system | Read only to find the default state directory on Linux and Windows. Not Desnarl settings. |
| `CROSSREPOGRAPH_DISABLE_LICENSE_CHECKIN` | off | `true` (any case) or `1` switches off the [license check-in](./license-check-in.md): nothing is sent, no `checkin-state.json` is written, nothing blocks. |
| `CROSSREPOGRAPH_CHECKIN_URL` | `https://desnarl.com/api/license/check-in` | Replaces the check-in endpoint, for a test host. Must be `https` with exactly that path. An invalid value turns the check-in off. |
| `CROSSREPOGRAPH_CHECKIN_ALLOW_INSECURE_LOOPBACK` | off | `true` (any case) or `1` lets `CROSSREPOGRAPH_CHECKIN_URL` use `http` to `127.0.0.1`, `localhost` or `[::1]` only. For tests. |
| `CROSSREPOGRAPH_DISABLE_REGISTRY_RESOLUTION` | off | `true` or `1` switches off the npm registry lookup that `crossrepo_consumers` uses for resolved versions. Version checks then compare declared ranges only, and say so. See [Registry-resolved version-skew checks](./deployment.md#registry-resolved-version-skew-checks). |
| `CROSSREPOGRAPH_DISABLE_WARMUP` | off | `true` or `1` stops the background read of your repos at start-up. Queries still read repos when they need them. Exactly `true` or `1`; `TRUE` does not count. |
| `CROSSREPOGRAPH_CORRECTIONS` | off | `true` or `1` turns on the [corrections beta](#corrections-beta). Exactly `true` or `1`. |

The older name `CROSSREPO_GRAPH_LICENSE_KEY` is no longer read. Rename it to `CROSSREPOGRAPH_LICENSE_KEY`.

## Running without outbound access

On a machine that cannot reach the internet, set both of these:

```json
"env": {
  "CROSSREPOGRAPH_LICENSE_KEY": "crg_your-license-key",
  "CROSSREPOGRAPH_DISABLE_LICENSE_CHECKIN": "true",
  "CROSSREPOGRAPH_DISABLE_REGISTRY_RESOLUTION": "true"
}
```

This is a supported way to run Desnarl. With both set, v0.2.0 makes no network call. What you give up: version checks use declared ranges only, and the portal can no longer tell the instance about a payment problem or a revoked key, so none of those notices or blocks will appear. Licensing stays self-attested and your license terms apply whether or not the check-in is on. Getting the package or image onto the machine in the first place still needs network access somewhere.

## Corrections (beta)

With `CROSSREPOGRAPH_CORRECTIONS=true` the server registers two more tools and writes a file `corrections.jsonl` in the state directory:

- `crossrepo_report_false_positive` records that a consumer returned by `crossrepo_impact` is wrong. The report is stored but **held**: it does not change answers.
- `crossrepo_report_false_negative` records a real consumer that `crossrepo_impact` missed. The addition **is applied** to later answers, labelled unverified.

Both apply to symbol-import edges only. They write to your local files and send nothing anywhere. The `confirmedBy` and `evidence` fields are whatever the caller supplies and are not verified, so do not hand these tools to an agent that reads untrusted input. While the flag is on, `crossrepo_impact` and `crossrepo_consumers` answers can carry a "Corrections (beta)" note listing what was applied, held or stale. This is a beta: the behaviour may change, and the server exposes more than the [eight standard tools](../mcp-tools/reference.md) while it is on.
