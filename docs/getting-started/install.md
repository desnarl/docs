---
sidebar_position: 1
title: Install
---

# Install

**Requirements:** Node.js >= 24.

## Supported languages

Desnarl reads **TypeScript and Go** repos only. A subdirectory counts as a repo if it has a `package.json` or a `go.mod` at its top level. **Python is not supported in `v0.2.0`.** Support for it is planned after launch, with no date. A Python repo in your workspace is not read, so an empty result for something Python code depends on does not mean nothing depends on it.

## Build from source

```bash
npm install
npm run build
```

This produces `dist/mcp/index.js` — the stdio MCP server entry point.

:::caution Distribution channel not finalized
This section documents the source build (clone → `npm install` → `npm run build`), which is what's confirmed working today. A packaged distribution (npm package, container image, or GitHub release) is not yet decided — this page will be updated once it is. Don't build tooling against an assumed package name or image tag; none is official yet.
:::

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
      "command": "node",
      "args": [
        "/absolute/path/to/crossrepograph/dist/mcp/index.js",
        "/absolute/path/to/your-workspace"
      ],
      "env": {
        "CROSSREPOGRAPH_LICENSE_KEY": "crg_your-license-key"
      }
    }
  }
}
```

The `env` block passes the license key from the section above. The workspace root is a required positional argument — the server fails fast with a clear error if it's missing or not a directory, rather than starting silently and failing later once a tool is called.

Not every client uses this `mcpServers` format, and clients differ in how they show tools. See [Client compatibility](./compatibility.md) for the clients we have tested.

## Where your data goes

There is no indexing step. Desnarl reads your repos the first time you ask a question that needs them, then keeps what it parsed in a cache, one per workspace, in a separate **state directory**. The server never writes into your repos, so there is nothing to add to a `.gitignore`. (The one-off [`init` command](#set-it-up-with-init) is the only thing that edits files outside the state directory, and only the two it shows you first.) The server prints the state directory's location on stderr at startup. The first query on a large workspace is slow, because nothing is cached yet; later ones re-read only the repos whose files changed. See [What Desnarl keeps on disk](../self-hosted/state-directory.md) for the location on each system and how the cache is refreshed.

## Make your agent use it

Connecting the server does not make an agent use it. Left alone, many agents answer a dependency question with `grep -r`. Three small steps fix that. The examples below use Claude Code's file formats; other clients have their own equivalents.

### Set it up with `init`

`crossrepograph init` does the next two steps for you, for Claude Code:

```bash
node /absolute/path/to/crossrepograph/dist/mcp/index.js init /absolute/path/to/your-workspace
```

It shows a diff of what it would change and asks before writing. It edits two files:

- `CLAUDE.md` in the workspace root. It adds the block from the next step between `<!-- crossrepograph:start -->` and `<!-- crossrepograph:end -->`.
- A Claude Code settings file, where it adds the six allow rules from the step after that. By default this is `~/.claude/settings.json`, so the rules apply in every repo under your workspace. The diff header shows the exact path.

Running it again changes nothing. Each file it modifies is first copied to `<file>.crossrepograph.bak`, which you may want in your `.gitignore`. It also writes `init-manifest.json` into the [state directory](../self-hosted/state-directory.md), recording what it added, so that `uninit` can remove exactly that.

| Option | What it does |
|---|---|
| `--dry-run` | Show the diff and write nothing. |
| `--yes` | Apply without asking. Required when there is no terminal: without it, `init` shows the changes and stops. |
| `--scope local\|project\|user` | Which settings file gets the allow rules: `user` is `~/.claude/settings.json` (the default), `project` is `.claude/settings.json` in the workspace root, `local` is `.claude/settings.local.json` there. |
| `--client claude-code` | The only client supported today. |
| `--server-name <name>` | Use this name in the block and the rules, if you named the server something other than `crossrepograph`. |

Claude Code reads a settings file in a project folder only for sessions started in that exact folder, not in the repos beneath it. That is why `user` is the default. If you choose `local` or `project` and the workspace root is not itself a git repository, `init` says so.

It does not read your license key, and it does not edit your `mcpServers` entry: it prints the entry to paste. A settings file with comments or trailing commas is left alone and the rules are printed for you to add by hand. The steps below show what it writes, so you can do the same by hand for another client.

### Tell the agent to prefer the tools

Paste this into your agent's instructions file (`CLAUDE.md` for Claude Code), in the repo you work from:

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

By default the client asks before every tool call. The six query tools only read, so you can allow them. In Claude Code, add this to `.claude/settings.json`:

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

## Undo it

You can reverse everything in "Make your agent use it" by hand. Do the first two to stop nudging the agent, the third to disconnect the server, and the fourth only if you want the cached data gone.

### Remove the instructions

Open the instructions file you pasted into (`CLAUDE.md` for Claude Code) and delete the whole block: from the `## Cross-repo dependency questions` heading down to and including the `ToolSearch` line at the end. If you also put the two comment lines `<!-- crossrepograph:start -->` and `<!-- crossrepograph:end -->` around it, delete those too.

### Remove the allow rules

In the settings file where you added them, delete the six rules listed under [Allow the read-only tools](#allow-the-read-only-tools), and nothing else. Leave any rules you already had. If you used a server name other than `crossrepograph`, the rule names carry that name. `crossrepo_confirm` and `crossrepo_confirm_schema_ref` were never in the list, so there is nothing to remove for them.

### Remove the server

This is a separate step, because it removes the connection itself, not just the nudge to use it. Delete the `crossrepograph` entry from `mcpServers` in your client's configuration, then restart the host. **That entry holds your license key in its `env` block, so copy the key somewhere safe first.** Deleting the entry deletes it from that file.

### Leave or delete the state directory

Nothing above touches the [state directory](../self-hosted/state-directory.md); it stays in place. Deleting it is safe, because `graph.db` is a cache that is rebuilt on the next query. It also deletes the savings report and the query log, including any confirmations you recorded, so keep a copy of those first if you want them.

### Or run `uninit`

`crossrepograph uninit` reverses what `init` did:

```bash
node /absolute/path/to/crossrepograph/dist/mcp/index.js uninit /absolute/path/to/your-workspace
```

It takes the same `--dry-run`, `--yes`, `--scope` and `--server-name` options as `init`, shows a diff, and asks first. Using `init-manifest.json`, it removes the block and only the rules that `init` added, so a rule you already had stays. It deletes a file only if `init` created it and it is now empty. If you edited the block, it asks before removing it, and with `--yes` it keeps the block. Without a manifest, it removes a block between the two marker lines and the six documented rules, and says so. Backups are written first, as for `init`.

It does not edit your `mcpServers` entry, so remove that yourself as above, and it never deletes the state directory.

## Restarting after an update

After changing the license key, restart the host (see [above](#if-the-key-is-missing-or-malformed)). The same goes for any other change. If you already have a connected MCP session open when Desnarl's code changes (a version upgrade, a config change), restart that session's connection — not just the server process — to pick up any change in tool shape.

## Next

- [Self-hosted deployment](../self-hosted/deployment.md) — ingestion auth, the network-queryable CI endpoint, storage, and staleness monitoring (built, not yet active).
- [What Desnarl keeps on disk](../self-hosted/state-directory.md) — where the state directory is, what each file is, and how the cache is built and refreshed.
- [MCP tool reference](../mcp-tools/reference.md) — what all eight tools take and actually return.
- [Client compatibility](./compatibility.md) — the AI coding tools we have tested Desnarl with, and what we have not.
