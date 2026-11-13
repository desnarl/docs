---
sidebar_position: 6
title: Troubleshooting
---

# Troubleshooting & recovery

This page covers the recovery scenarios that are documented today. A license check-in that is stuck, showing an "unverified" notice or blocking, is covered in [License check-in](./self-hosted/license-check-in.md#if-you-are-blocked-or-see-an-unverified-notice). A missing or malformed license key is covered below.

## SQLite corruption

`graph.db`, in your [state directory](./self-hosted/state-directory.md), is a single SQLite file; on-disk corruption (a killed process mid-write with WAL not yet checkpointed, a bad disk sector, a partial volume-mount copy) surfaces as SQLite's own error on next open, most commonly `database disk image is malformed`.

There is no in-place repair path for a corrupted `.db` file. `graph.db` is a cache, so the fix is to stop the server, delete `graph.db`, `graph.db-wal` and `graph.db-shm`, and start it again: it recreates the database and reads every repo again on the next query, which is slow once. Do not delete the rest of the state directory unless you mean to: `query-log.jsonl` holds your confirmations (see [What Desnarl keeps on disk](./self-hosted/state-directory.md#deleting-graphdb)). If you keep backups of the state directory (see [Self-hosted deployment → Storage & upgrades](./self-hosted/deployment.md#storage--upgrades) for what a valid backup requires), restoring one also works. There is currently no automated corruption *detection* separate from the open failing outright.

## A repo is listed as `path_outside_repo` {/* #path-outside-repo */}

`path_outside_repo` is a reason in `unresolvableRepos` on `crossrepo_consumers` and `crossrepo_impact`. It means a `package.json` in that sibling repo (or its `pnpm-workspace.yaml`) names a path that points outside the repo's own checkout, so Desnarl did not read it. The fields checked are `main`, `types`, `exports` and `workspaces`, and a default entry file such as `index.js` or `src/index.ts`. An absolute path, a `..` path that leaves the repo, and a path that resolves through a symlink to somewhere outside the repo all count. A symlink or other non-regular file at the named path is rejected too, even if it points to a place inside the same repo.

A repo with a symlinked workspace directory is reported as a whole under this reason today: if a `workspaces` pattern matches a symlink, the whole repo is listed in `unresolvableRepos`, not only that directory. None of that repo's packages are resolved. Replace the symlink with a real directory (or change the pattern) if you want the repo read.

This is a safety limit, not a failure: a sibling repo is untrusted input, so a path it names is not followed out of its checkout. A target that does not exist yet (an unbuilt `dist/`) is not a `path_outside_repo` case.

## Other `unresolvableRepos` reasons {/* #unresolvable-reasons */}

Besides `path_outside_repo`, `manifest_too_large`, `missing_entry_file`, `no_entry_declared` and `scan_limit_reached` (described above and in the [tool reference](./mcp-tools/reference.md#scope-and-limitations)), three reasons name a `package.json` problem:

- **`invalid_package_json`:** the repo's `package.json` is not valid JSON. Fix the file.
- **`unsupported_workspaces_glob`:** a `workspaces` pattern is something other than a literal path or a whole-segment `*`. Use a form Desnarl reads, or list the packages explicitly.
- **`missing_glob_target`:** a `workspaces` pattern names a directory that does not exist. Fix the pattern or check out the missing folder.

In each case the repo is named, not dropped, so an answer that lists it is not proof of no impact.

## Files were skipped (`skippedFiles`) {/* #skipped-files */}

`crossrepo_consumers`, `crossrepo_impact`, `crossrepo_schema_refs` and `crossrepo_deployment_refs` list files they did not read in a `skippedFiles` field: `skipped_oversize` for a file over its size cap, `skipped_timeout` for a file whose parse took more than 2 seconds, and `skipped_unsafe_path` for a file that was a symlink or not a regular file, so it was not read and the answer may be missing something that file declares (today only `crossrepo_deployment_refs` reports this one). A repo whose `package.json` or `pnpm-workspace.yaml` is over 1 MiB is listed in `unresolvableRepos` with the reason `manifest_too_large`.

A skipped file is a possibly missing consumer, so an answer from a repo that has one is not proof of no impact. The caps, the exact field shape and which tools report skips are in the [tool reference](./mcp-tools/reference.md#skipped-files). There is nothing to fix on your side except to check the named file by hand (for `skipped_unsafe_path`, replacing the symlink with a real file also works); a `skipped_timeout` can depend on machine load, and the next query tries the file again.

## Docker image fails to pull or run

The image is published to `ghcr.io/desnarl/crossrepograph` on each tagged release. A pull failure is most often one of two causes, not a broken image:

- **The package is still private.** GHCR container packages default to private on their very first publish. If `docker pull ghcr.io/desnarl/crossrepograph:<tag>` returns `denied` or `unauthorized` with no credentials configured, this is the most likely cause — check whether the package has been made public yet before assuming your own setup is wrong.
- **`linux/amd64` only.** This image is built for `linux/amd64` only as of Phase 2 — running it on an ARM host (e.g. Apple Silicon without Rosetta, an ARM-based cloud instance) will either fail to pull a matching manifest or run under slow binary translation. There is no multi-arch build yet.

## `crossrepo_consumers` returns no consumers

An empty `consumers` list has four common causes. Check them in this order:

1. **The package is third-party and nothing imports it.** For a package no checked-out sibling repo publishes (`zod`, `react`), Desnarl lists the files in sibling repos that import it, and sets `importBased: true`. An empty list then means no TypeScript or JavaScript file imports it by that name: side-effect-only imports, path aliases and Go are not counted (see [`crossrepo_consumers`](./mcp-tools/reference.md#crossrepo-consumers)).
2. **The publishing repo isn't checked out.** If the package is yours but its repo isn't a sibling folder under the workspace root, nothing resolves it. Look at `missingSiblings` for a scoped dependency that no checked-out sibling provides.
3. **A repo couldn't be read.** A sibling whose `package.json` can't be parsed, whose declared entry point isn't built (`missing_entry_file`), or that has a name but declares no entry (`no_entry_declared`), appears in `unresolvableRepos`. So does a repo with a `path_outside_repo` or `manifest_too_large` reason (both explained below), and a repo whose folder tree was too large to finish scanning for nested manifests (more than 500 directories, `scan_limit_reached`): it may hold modules that were not looked for. A repo whose manifests are only in subfolders is searched, not listed. Check that field before trusting a short or empty list.
4. **A file in a repo was skipped.** A file over its size cap, or one that took more than 2 seconds to parse, is not read and may have been a consumer. Look for `skippedFiles` in the result. See [A repo is listed as `path_outside_repo`](#path-outside-repo) and [Files were skipped](#skipped-files) below.

If `consumers` is empty or shorter than you expected, look at `declaredOnlyRepos` too. `declaredOnlyRepos` lists repos whose manifest declares this package but where no import of it was found. This is not proof the dependency is unused: it can be used by a config file, a CLI script, another language (Python, shell) or as a peer or transitive dependency. It says "declares X at range R but no import found", nothing more.

For a package a sibling publishes, an import of a subpath (`@your-scope/pkg/sub`) is counted only when that package's `exports` map allows it. For a third-party package, any subpath import counts, marked `importBased`. For how a package is judged internal, see [`crossrepo_consumers`](./mcp-tools/reference.md#crossrepo-consumers). `versionSkew` is only meaningful once `consumers` is non-empty.

## Server does not start, or shows as failed {/* #server-does-not-start */}

Run the server from a terminal with the same arguments and environment your client uses, and read stderr. These are the messages it can print and what to do. (A missing or malformed license key is a separate case, covered in the next section.)

| Message on stderr | Cause and fix |
|---|---|
| `Usage: crossrepograph-mcp <workspace-root> ...` | No workspace argument. Add the absolute path of the folder that holds your repos as the last argument. |
| `Workspace root must be an absolute path: ...` | A relative path was given. Use an absolute path: a client launches the server from a folder you do not control. |
| `Workspace root does not exist: ...` or `... is not a directory` | The path is wrong, or (in the container) is not mounted where you think. |
| `CROSSREPOGRAPH_STATE_DIR must be an absolute path, got: ...` | Set the variable to an absolute path. |
| `State directory ... is inside the workspace being indexed ...` | The state directory, set or default, resolves inside the workspace. Set `CROSSREPOGRAPH_STATE_DIR` to a path outside it. |
| `Cannot create or write to the state directory ...` | The folder cannot be created or written. Set `CROSSREPOGRAPH_STATE_DIR` to a writable absolute path, or in the container mount a volume at `/state` that uid 1000 can write. |
| `state directory ... is group- or world-accessible (mode ...)` | A warning, not a failure. The folder holds repo structure and the query log; run `chmod 700` on it. |
| `Database schema user_version (N) is newer than any migration this build knows about ...` | `graph.db` was written by a newer release than the one you are running. Run the newer release again, or delete `graph.db*` (see above) to start fresh. |
| `old state found at ... set CROSSREPOGRAPH_STATE_DIR to keep using it` | A notice about the `.crossrepograph/` folder an earlier build left in its checkout. Not an error. |
| `crossrepograph: cache warm-up failed: ...` | The background read of your repos failed. The server keeps running and the next query reads the repos itself. If it repeats, the reason names the cause. |
| `crossrepograph: CROSSREPOGRAPH_CHECKIN_URL is not a valid https endpoint, so the licence check is off.` | The override is not an `https` URL with the exact path `/api/license/check-in`. The check-in is off until you fix or unset it. |

If the client shows the server as failed but nothing prints in a terminal, the likely causes are: Node.js older than 24 (check `node -v` in the environment the client uses, which for a desktop client is not always your shell's), a client that cannot find `npx` on its `PATH`, or a cold `npx` download that outlasted the client's start-up timeout (run `npm i -g @desnarl/crossrepograph` once, then use the command `crossrepograph`). A failed query-log or report write is also reported on stderr but does not fail the tool call.

## Only `crossrepo_license_required` appears, or Desnarl's tools are missing

With no license key, or one that is not `crg_` followed by 32 lowercase letters or digits, the host connects and shows a single tool, `crossrepo_license_required`. Its text tells you to set `CROSSREPOGRAPH_LICENSE_KEY`. The eight query tools do not appear. The server also prints the message on stderr, which you will see if you launch it from a terminal.

Fix: set `CROSSREPOGRAPH_LICENSE_KEY` in the environment the host passes to the server (for example the `env` block in the [install page](./getting-started/install.md#add-it-to-your-mcp-client)), then restart the host. We have not verified that any host refreshes its tool list without a restart. If the tools are missing and `crossrepo_license_required` is not shown either, check the key first, then see [Client compatibility](./getting-started/compatibility.md#missing-key).

A bad key does not make the server exit with an error: it stays connected and exits 0 when stdin closes.

## How long should a query take?

On a 12-repo workspace of about 10,000 files (an Apple M4 with 32 GB of RAM), the first query after the server started took about 1 second, and later queries about 0.7 seconds. Starting the server and connecting adds about half a second. Times grow with the number of repos and files, and depend on your disk.

If a query takes much longer than that, the cause is usually the workspace or the machine rather than normal operation. Check that no other heavy process is running. Query results report how much of the cache was used, in the `cache` field described under [Cache fields](./mcp-tools/reference.md#cache-fields).

*Measured on 2026-10-05, against `crossrepo_consumers` and `crossrepo_impact`, on engine commit `527874d`.*

## Getting help

**Bug reports and feature requests** go to Issues on the public repository, [`desnarl/crossrepograph`](https://github.com/desnarl/crossrepograph/issues). Issues are public, and they are not a support channel: there is no promised response time. **Never post a license key, the contents of `query-log.jsonl` or `graph.db`, repo or package names you treat as confidential, or file paths from your workspace.** Share the Desnarl version, the exact error line printed on stderr, and the text of any notice a tool result showed (for example an unverified or payment-problem notice).

**Problems with your license or payment** go through an **in-portal ticket system**, from inside the license portal at [desnarl.com](https://desnarl.com) once you have created an account and signed in. That system is not live yet; this page will link to it once it ships.

**There is no email support and no public Discord (or other community) support channel, for any tier.** Desnarl v0.2.0 has no self-diagnostic report, so there is nothing to export. Never send `graph.db`, `query-log.jsonl` or any indexed repo content off your own network for debugging: Desnarl's data-custody guarantee depends on that content staying with you, and a bug report is not an exception to it.
