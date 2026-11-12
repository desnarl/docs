---
sidebar_position: 1
title: Install
---

# Install

**Requirements:** Node.js >= 24 (for the npm package), or a container runtime (for the image). Desnarl reads your repos from disk and writes its cache to a [state directory](../self-hosted/state-directory.md) outside them, so the user running the server needs read access to the workspace and write access to that directory.

## Supported languages

Desnarl reads **TypeScript and Go** repos only. A subdirectory counts as a repo if it has a `package.json` or a `go.mod` at its top level. **Python is not supported in `v0.2.0`.** Support for it is planned after launch, with no date. A Python repo in your workspace is not read, so an empty result for something Python code depends on does not mean nothing depends on it.

## Choose an install channel

Every channel needs a [license key](#license-key) and runs the same server over stdio. Your MCP client launches it; you do not start it yourself.

| Channel | Use it when | How |
|---|---|---|
| **npm, through `npx`** (primary) | You use an MCP client on your own machine | Put `npx -y @desnarl/crossrepograph <workspace-root>` in the client's MCP configuration (below). Nothing to install first. |
| **npm, global install** | You want the first start to be fast, or to pin a version | `npm i -g @desnarl/crossrepograph`, then use the command `crossrepograph` in the client's configuration. |
| **Container image** | A locked-down machine or a container-based setup | `ghcr.io/desnarl/crossrepograph`. See [Run the container image](../self-hosted/docker.md). |

All three are published from the same release tag. The [GitHub release](https://github.com/desnarl/crossrepograph/releases) lists the image pull command pinned to a digest, the npm package name and the checksum of the npm tarball.

**The first start is slower.** The first `npx` run downloads the package and its native tree-sitter grammars, so the first start takes longer than later ones, and a client with a short start-up timeout can mark the server as failed on that first launch. If that happens, run `npm i -g @desnarl/crossrepograph` once and restart the client. We have not measured how long a cold download takes.

**Versions and tags.** A plain release tag such as `v0.2.0` publishes to the npm `latest` tag. A tag with a hyphen (a pre-release) publishes to `next` and never to `latest`. The image follows the same rule for its `latest` tag. npm releases are staged and go live only when a maintainer approves them, so a GitHub release can appear a little before the npm version does.

**The image is built for `linux/amd64` only.** On an ARM host it will not pull a matching image, or will run under slow emulation. Use the npm package there.

**Building from source** is for contributors, not for using Desnarl. It is `npm install` then `npm run build` in a checkout of [`desnarl/crossrepograph`](https://github.com/desnarl/crossrepograph), which produces `dist/mcp/index.js`. Point `"command": "node"` at that file in place of the `npx` line below.

## License key

Desnarl's tools are unavailable without a license key, even for non-commercial use. Set it in the `CROSSREPOGRAPH_LICENSE_KEY` environment variable. The key must be `crg_` followed by exactly 32 lowercase letters or digits. The check is on the format only and runs offline: it makes no network call.

{/* Key-request wording and link live in this one paragraph; replace it when the self-serve portal ships (2.5.7 with 2.5.12). */}
Early keys are issued by hand. Request one at [desnarl.com/request-key](https://desnarl.com/request-key); the form is for free and noncommercial keys, and the key is sent to you privately. Do not ask for a key, or post one, in a GitHub issue or discussion: those are public. A self-serve portal that issues keys automatically is planned but is not built yet, and this page will change when it is.

### If the key is missing or malformed

The server still starts and completes the MCP handshake, so your client shows it as connected. It exposes exactly one tool, `crossrepo_license_required`, and none of the eight [query tools](../mcp-tools/reference.md). The tool's description and the server's MCP instructions carry the same text, which tells you to set `CROSSREPOGRAPH_LICENSE_KEY`; calling the tool returns that text. In this state the server opens no database, reads no workspace and makes no network call.

If you launch the server from a terminal, the same message is also printed on stderr. The deprecated `CROSSREPO_GRAPH_LICENSE_KEY` variable still produces its warning on stderr, unchanged.

A bad key does not make the server exit with an error. It stays up and exits with code 0 when its stdin closes, so a script that expected a non-zero exit for a bad key will no longer see one.

After you set or fix the key, restart the host so it starts the server again with the new value. We have not verified whether any given host refreshes its tool list without a restart, so do not rely on that.

## Add it to your MCP client

Point it at the workspace root directory that contains your sibling repos as immediate subdirectories. The layout must be flat: a subdirectory counts as a repo if it has a `package.json` or `go.mod` at its top level, or one within three folders below it (a monorepo of services, or a repo whose manifests live in `apps/` or `cmd/`). Checkouts nested deeper than that are not found:

```json
{
  "mcpServers": {
    "crossrepograph": {
      "command": "npx",
      "args": [
        "-y",
        "@desnarl/crossrepograph",
        "/absolute/path/to/your-workspace"
      ],
      "env": {
        "CROSSREPOGRAPH_LICENSE_KEY": "crg_your-license-key"
      }
    }
  }
}
```

With a global install, use `"command": "crossrepograph"` and drop the first two `args`.

The `env` block passes the license key from the section above. The workspace root is a required positional argument and must be an absolute path. The server fails fast with a clear error on stderr if it is missing, relative, does not exist or is not a directory, rather than starting and failing later once a tool is called (see [Troubleshooting](../troubleshooting.md#server-does-not-start)).

Not every client uses this `mcpServers` format, and clients differ in how they show tools. See [Client compatibility](./compatibility.md) for the clients we have tested.

### Register it where you start your sessions

Some clients keep a server registration against the folder you added it from, so it is only available to sessions started in that folder. Claude Code does this by default: a server added with `claude mcp add` is stored for the current folder only. Desnarl is for workspaces of several repos, and people often start a session inside one repo rather than at the workspace root, so a registration made at the root is missing there.

Register it for your whole user account instead (in Claude Code, `claude mcp add --scope user ...`), or once for each folder you start sessions in. Check from a repo folder that the tools are listed. The server's workspace argument stays the workspace root either way; only where the client remembers the registration changes.

## Where your data goes

There is no indexing command to run. When the server starts with a valid key, it begins reading your repos in the background, on a separate thread, and stores what it parses in a cache, one per workspace, in a separate **state directory**. It never writes into your repos, so there is nothing to add to a `.gitignore`. The server prints the state directory's location on stderr at startup, and two lines when the background read ends: `crossrepograph: cache warm-up finished (N repos, M already cached, T ms)`, or `crossrepograph: cache warm-up failed: <reason>`. A failed warm-up does not stop the server; the next query reads the repos itself.

Queries do not wait for the background read, so the first query on a large workspace can still be slow, and later ones re-read only the repos whose files changed. We have not measured how much the background read shortens the first query. To switch it off, set `CROSSREPOGRAPH_DISABLE_WARMUP=true`. See [What Desnarl keeps on disk](../self-hosted/state-directory.md) for the location on each system and how the cache is refreshed, and [Configuration](../self-hosted/configuration.md) for every setting.

## Make your agent use it

Connecting the server does not make an agent use it. Left alone, many agents answer a dependency question with `grep -r`. Three small steps fix that. The examples below use Claude Code's file formats; other clients have their own equivalents.

### Do it with one command (Claude Code)

`crossrepograph init` makes the two edits below for you, and `crossrepograph uninit` reverses them. It supports Claude Code only; for any other client, make the edits by hand as described in the next two sections.

```sh
npx -y @desnarl/crossrepograph init /absolute/path/to/your-workspace --dry-run   # show the changes only
npx -y @desnarl/crossrepograph init /absolute/path/to/your-workspace             # show them, then ask
```

With a global install, run `crossrepograph init ...` instead. The workspace argument is optional and defaults to the current folder. What it does:

- **Adds the instruction block to `CLAUDE.md` in the workspace root.** The block sits between `<!-- crossrepograph:start -->` and `<!-- crossrepograph:end -->`. If you already have a block, it is replaced in place; text outside the markers is not touched. If the markers are unbalanced it stops and tells you.
- **Adds the six read-only allow rules to a Claude Code settings file.** The file depends on `--scope`: `user` (the default) is `~/.claude/settings.json`; `project` is `.claude/settings.json` in the workspace root; `local` is `.claude/settings.local.json` in the workspace root. A rule that is already in your `deny` or `ask` list is skipped, and your other rules are kept. `crossrepo_confirm` and `crossrepo_confirm_schema_ref` are never added.
- **Does not edit your MCP client configuration.** It prints the `mcpServers` entry for you to add yourself, with a placeholder key. It never reads your license key.
- **Shows a diff and asks before writing**, unless you pass `--yes` (or `-y`). Without a terminal and without `--yes` it shows the changes and exits with status 2. `--dry-run` writes nothing. Each file it changes first gets a backup next to it whose name ends in `.crossrepograph.bak`; add those to a `.gitignore` if you do not want them committed.
- **Records what it changed** in the state directory, so that `uninit` can undo exactly that. Use `--server-name <name>` if you registered the server under a name other than `crossrepograph`; the allow rules carry that name. If you ran `init` with one scope, `uninit` first, or pass the same scope, before using another.

### Tell the agent to prefer the tools

Paste this into your agent's instructions file (`CLAUDE.md` for Claude Code), in the repo you work from. In Claude Code you can instead put one copy at the workspace root: Claude Code also reads `CLAUDE.md` from parent folders, so a session started in any repo below the root receives it (checked on Claude Code 2.1.319). Other clients may not read parent folders; check yours.

````markdown
## Cross-repo dependency questions

For "what depends on this", "what consumes this" and "what breaks if I change this" questions that span repos, use the crossrepograph MCP tools before `grep -r` or reading files across repos:

- `crossrepo_impact` — `{ "symbol": "checkRateLimitWithPolicy", "sourceRepo": "internal-packages" }`: which repos and files use an exported symbol.
- `crossrepo_consumers` — `{ "packageName": "@your-scope/rate-limit" }`: which repos and files import a package.
- `crossrepo_schema_refs` — `{ "schemaOrTableName": "widgets" }`: which repos and files reference a table or schema.

Fall back to grep only for what the tools do not read, such as languages other than TypeScript and Go.

If your client defers MCP tools and they are not callable yet, load them first with
ToolSearch `select:mcp__crossrepograph__crossrepo_impact,mcp__crossrepograph__crossrepo_consumers,mcp__crossrepograph__crossrepo_schema_refs`
````

Replace `crossrepograph` in the `select:` string with the key you used under `mcpServers`. The prefix is `mcp__<server-name>__`. See the [MCP tool reference](../mcp-tools/reference.md) for all eight tools, including `crossrepo_deployment_refs`, `crossrepo_cicd_refs` and `crossrepo_topic_refs`.

### Allow the read-only tools

By default the client asks before every tool call. The six query tools only read, so you can allow them. In Claude Code, add this to `.claude/settings.json`. That file applies only to sessions started in the folder that holds it: we found that a session started in a repo folder did not use the rules in a `.claude/settings.json` at the workspace root, and was asked before every call (checked on Claude Code 2.1.319). To allow the tools in every repo, add the same rules to your user settings file, `~/.claude/settings.json`, instead; or add the file to each repo you start sessions in.

```json
{
  "permissions": {
    "allow": [
      "mcp__crossrepograph__crossrepo_impact",
      "mcp__crossrepograph__crossrepo_consumers",
      "mcp__crossrepograph__crossrepo_schema_refs",
      "mcp__crossrepograph__crossrepo_deployment_refs",
      "mcp__crossrepograph__crossrepo_cicd_refs",
      "mcp__crossrepograph__crossrepo_topic_refs"
    ]
  }
}
```

The middle part of each name is the server name: whatever key you used in `mcpServers`. If you named it something other than `crossrepograph`, use that name here.

`crossrepo_confirm` and `crossrepo_confirm_schema_ref` are deliberately left out. They record a decision rather than read one, so they should keep prompting.

### Check that it is working

Open the savings report ([The savings report](../self-hosted/savings-report.md)). If `savings-audit-report.md` shows **Applicable but unused**, your workspace has cross-repo links but the agent has made no calls: it is not reaching for the tools, so check that its instructions mention them.

## Your first query

Restart your client, check that the Desnarl tools are listed, then ask your agent a question that crosses repos. Name a symbol and the repo folder that exports it (`sourceRepo` is the folder name under your workspace root):

> Which repos in this workspace import `checkRateLimitWithPolicy` from `internal-packages`? Use the Desnarl tools, not grep.

The agent should call `crossrepo_impact` with `{ "symbol": "checkRateLimitWithPolicy", "sourceRepo": "internal-packages" }`. A good answer names each consuming repo and file with a line number, and says what it could not read. Open one of the named files to confirm the import is there. Read these fields before you trust a short or empty answer: `unresolvableRepos`, `skippedFiles`, `missingSiblings`, `truncated` and `coverage` (see [reading a result](../mcp-tools/reference.md#reading-a-result)).

Which tool for which question:

| You want to know | Tool |
|---|---|
| Who uses this exported function, class or type | `crossrepo_impact` |
| Who depends on this package, and on which versions | `crossrepo_consumers` |
| Which repos touch this database table or column | `crossrepo_schema_refs` |
| Which repos deploy or reference this service or image | `crossrepo_deployment_refs` |
| Which repos' GitHub Actions call into this repo | `crossrepo_cicd_refs` |
| Who publishes or subscribes to this message topic (Go only) | `crossrepo_topic_refs` |
| Record that an earlier answer missed a consumer, or that an HTTP match was right or wrong | `crossrepo_confirm`, `crossrepo_confirm_schema_ref` (these write to the query log; a person or your own pipeline calls them, not a reading agent) |

An empty result means only that no TypeScript, JavaScript or Go file in the checked-out repos matched. It says nothing about repos that are not checked out, other languages, or HTTP calls between services.

## Undo it

If you used `crossrepograph init`, run `crossrepograph uninit` (same workspace and `--scope`) to reverse its two edits; it removes the block and the rules it added, asks before removing a block you have edited since, and removes the settings file or folder only if `init` created it. `uninit` does not touch your MCP client configuration or the state directory, so the last two steps below are always yours to do. To reverse it by hand instead: do the first two steps to stop nudging the agent, the third to disconnect the server, and the fourth only if you want the cached data gone.

### Remove the instructions

Open the instructions file you pasted into (`CLAUDE.md` for Claude Code) and delete the whole block: from the `## Cross-repo dependency questions` heading down to and including the `ToolSearch` line at the end. If you also put the two comment lines `<!-- crossrepograph:start -->` and `<!-- crossrepograph:end -->` around it, delete those too.

### Remove the allow rules

In each settings file where you added them (`~/.claude/settings.json`, a repo's `.claude/settings.json`, or both), delete the six rules listed under [Allow the read-only tools](#allow-the-read-only-tools), and nothing else. Leave any rules you already had. If you used a server name other than `crossrepograph`, the rule names carry that name. `crossrepo_confirm` and `crossrepo_confirm_schema_ref` were never in the list, so there is nothing to remove for them.

### Remove the server

This is a separate step, because it removes the connection itself, not just the nudge to use it. Delete the `crossrepograph` entry from `mcpServers` in your client's configuration, then restart the host. **That entry holds your license key in its `env` block, so copy the key somewhere safe first.** Deleting the entry deletes it from that file.

### Leave or delete the state directory

Nothing above touches the [state directory](../self-hosted/state-directory.md); it stays in place. Deleting it is safe, because `graph.db` is a cache that is rebuilt on the next query. It also deletes the savings report and the query log, including any confirmations you recorded, so keep a copy of those first if you want them.


## Updating and uninstalling the program

- **`npx`:** `npx -y` fetches the newest published version and caches it, so you may not get a newer release on a machine that already has one cached. To pick a version deliberately, put it in the `args`, for example `@desnarl/crossrepograph@<version>`.
- **Global install:** `npm i -g @desnarl/crossrepograph` again to update; `npm rm -g @desnarl/crossrepograph` to remove.
- **Image:** pull the new tag, and pin it by digest if you need repeatable runs. `docker rmi` removes it.

Desnarl does not tell you when a newer release exists. A newer build applies any pending cache migrations on its next start. See [Storage & upgrades](../self-hosted/deployment.md#storage--upgrades).

## Restarting after an update

After changing the license key, restart the host (see [above](#if-the-key-is-missing-or-malformed)). The same goes for any other change. If you already have a connected MCP session open when Desnarl's code changes (a version upgrade, a config change), restart that session's connection — not just the server process — to pick up any change in tool shape.

## Next

- [Configuration](../self-hosted/configuration.md) — every environment variable.
- [Run the container image](../self-hosted/docker.md) — the GHCR image.
- [Self-hosted deployment](../self-hosted/deployment.md) — the network calls v0.2.0 makes, storage and upgrades.
- [What Desnarl keeps on disk](../self-hosted/state-directory.md) — where the state directory is, what each file is, and how the cache is built and refreshed.
- [MCP tool reference](../mcp-tools/reference.md) — what all eight tools take and actually return.
- [Client compatibility](./compatibility.md) — the AI coding tools we have tested Desnarl with, and what we have not.
