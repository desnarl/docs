---
sidebar_position: 3
title: What Desnarl keeps on disk
---

# What Desnarl keeps on disk

Desnarl writes its own working files to one folder, the **state directory**. The server never writes into the repos it reads. The only other files Desnarl ever writes are the two that the one-off `crossrepograph init` command edits, after showing you the diff (see [Install](../getting-started/install.md#set-it-up-with-init)); those and their `.crossrepograph.bak` backups are not in the state directory. This page says where that folder is, what each file in it is, and what to keep out of version control and out of a support request.

## Where the state directory is

The server prints the folder on stderr every time it starts, as a line beginning `crossrepograph: state directory:`. Many MCP clients do not show a server's stderr, so the default location below is also worth knowing.

**You choose it:** set `CROSSREPOGRAPH_STATE_DIR` to an absolute path in the `env` block of the server's MCP configuration, next to the license key. A relative path is refused.

**Otherwise, a per-workspace default** under your operating system's user-data directory, so two workspaces never share one set of files:

| Where you run it | Default location |
|---|---|
| macOS | `~/Library/Application Support/crossrepograph/<workspace-name>-<hash>/` |
| Linux | `$XDG_STATE_HOME/crossrepograph/<workspace-name>-<hash>/`, or `~/.local/state/crossrepograph/<workspace-name>-<hash>/` when `XDG_STATE_HOME` is unset |
| Windows | `%LOCALAPPDATA%\crossrepograph\<workspace-name>-<hash>\` |
| Docker image | `/state`, declared as a volume |

`<hash>` is derived from the workspace's real path, so you cannot work it out by hand: list the parent folder and look for the one that starts with your workspace's name. **Moving or renaming a workspace changes the hash**, so the server starts with a fresh, empty state directory. The old one is left where it was.

The default does not depend on where your MCP client happens to launch the server from, and it lives outside the server's own install folder, so upgrading the install does not replace it.

The folder is created on first start, readable and writable by your user only (mode `0700` on macOS and Linux). If it cannot be created or written, the server prints a plain message on stderr and exits with a non-zero status. A missing or malformed license key never reaches this point: the server serves only `crossrepo_license_required` and touches no state.

### Docker

The image sets `CROSSREPOGRAPH_STATE_DIR=/state`. Mount a volume there, or the files are lost when the container is removed. The image runs as the `node` user (uid 1000), so a bind-mounted host folder must be writable by uid 1000.

### Earlier versions

Earlier builds kept this data in `.crossrepograph/` inside the checkout. Nothing is migrated automatically. If that folder still exists and `CROSSREPOGRAPH_STATE_DIR` is unset, the server prints a one-time notice on stderr naming it. To keep using the old data, set `CROSSREPOGRAPH_STATE_DIR` to that folder.

## What each file is

| File | What it is |
|---|---|
| `graph.db` | A SQLite cache of what Desnarl parsed from each repo (its exports and imports). Links between repos are worked out from it at query time. Safe to delete; see [How the index is built and refreshed](#how-the-index-is-built-and-refreshed). |
| `graph.db-wal`, `graph.db-shm` | SQLite's write-ahead log and its shared-memory index. They hold recent writes that are not yet in `graph.db`, and they come and go while the server runs. |
| `query-log.jsonl` | One line per tool call: the tool, the symbol or query you asked about, the result count, a timestamp, and the consuming repos the call returned. It is the source for the ledger below. |
| `query-ledger.md` | A readable summary regenerated from `query-log.jsonl`. |
| `savings-audit-log.jsonl` | One line per call, recording the figures behind the savings report. |
| `savings-audit-snapshot.json` | The latest per-workspace count of links by kind and repos by language, written as a by-product of a call. The savings report reads it instead of walking your workspace again. |
| `savings-audit-report.md` | The savings report. See [The savings report](./savings-report.md). |
| `monitoring-state.json` | Staleness-alert bookkeeping. Staleness monitoring is [built but not yet active](./deployment.md#staleness-monitoring), so expect this file only in an instance where you have started it yourself. |
| `init-manifest.json` | Written by `crossrepograph init`: what it added to `CLAUDE.md` and to the settings file, so that `uninit` can remove exactly that. Absent if you never ran `init`. |
| `repos/<repo-name>/` | Local clones of remote repos fetched by [ingestion](./deployment.md#ingestion-authentication). Present only if you use remote ingestion. |

The report and ledger files are regenerated after every tool call, so editing them by hand achieves nothing.

## How the index is built and refreshed

There is no indexing command to run, and no background process. Desnarl builds its cache on demand, inside tool calls.

- **Starting the server** opens `graph.db` and prepares it. It reads none of your repos.
- **The first `crossrepo_impact` or `crossrepo_consumers` call** reads every repo it needs and stores the result in `graph.db`. On a large workspace this call is slow, because nothing is cached yet: [measured at roughly 27 to 36 seconds](../mcp-tools/reference.md#scope-and-limitations) on a 13-repo workspace. Later calls are much faster. The other query tools do not use the cache.
- **Every call checks for changes.** The workspace's repo list is rebuilt on each call, so a repo you add is picked up by the next call. For each repo, Desnarl compares the size and modification time of its source files, manifests and built entry files (usually in `dist/`) with what it stored. A repo that differs is read again in full on that call, and one that matches is not. It does not compare file contents, so an edit that changes neither a file's size nor its modification time is not noticed.
- **The refresh is per repo, not per file, and it happens inside the call.** The call waits while it runs. Nothing watches your files between calls.
- **How to tell.** Each `crossrepo_impact` and `crossrepo_consumers` response carries `cacheHit` and `cache`, which show how many repos were served from the cache. See [Cache fields](../mcp-tools/reference.md#cache-fields). A response never says an answer is stale, because every call re-checks first.

### Deleting `graph.db`

`graph.db` holds nothing that cannot be rebuilt. If you delete it (with `graph.db-wal` and `graph.db-shm`), the server recreates it on the next start and every repo is read again on the next call, so the first call is slow again. Deleting it is also the fix if an older version refuses to start on a `graph.db` written by a newer one.

It is the one file here you can lose safely. Your confirmations from `crossrepo_confirm` and `crossrepo_confirm_schema_ref` are not in `graph.db`: they are written to `query-log.jsonl`, with the rest of the query log, and `crossrepo_confirm` can only confirm a call that is still in that log. Deleting the whole state directory loses them.

## Keep it out of version control

**Desnarl never creates or edits a `.gitignore` entry anywhere.** Two things keep the state directory out of your repos by default: the default location is outside your workspace, and the server refuses to start if the state directory, including one you set, resolves to a place inside the workspace it is indexing.

That does not cover every case. If you point `CROSSREPOGRAPH_STATE_DIR` into a folder that is inside some *other* git repository, add it to that repo's `.gitignore` yourself. The same applies to a `.crossrepograph/` folder left over from an earlier build.

## Treat the query log as sensitive

`query-log.jsonl` records what you and your agents asked about, and the repos each answer named. That can include **internal repo and package names**, which many organizations treat as confidential. The savings audit log, the ledger and the report carry repo names and counts too.

- Do not commit these files, paste them into an issue, or attach them to a support request.
- Do not send `graph.db` off your network. That includes sending it for debugging. See [Troubleshooting → Getting help](../troubleshooting.md#getting-help).
- Back up the whole folder as one set, and checkpoint `graph.db` first. The steps are in [Deployment guide → Storage & upgrades](./deployment.md#storage--upgrades).

None of these files is sent anywhere by Desnarl. The network calls it does make are listed in the [Deployment guide](./deployment.md).
