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

## Make your agent use it

Connecting the server does not make an agent use it. Left alone, many agents answer a dependency question with `grep -r`. Three small steps fix that. The examples below use Claude Code's file formats; other clients have their own equivalents.

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

## Restarting after an update

After changing the license key, restart the host (see [above](#if-the-key-is-missing-or-malformed)). The same goes for any other change. If you already have a connected MCP session open when Desnarl's code changes (a version upgrade, a config change), restart that session's connection — not just the server process — to pick up any change in tool shape.

## Next

- [Self-hosted deployment](../self-hosted/deployment.md) — ingestion auth, the network-queryable CI endpoint, storage, and staleness monitoring (built, not yet active).
- [MCP tool reference](../mcp-tools/reference.md) — what all eight tools take and actually return.
- [Client compatibility](./compatibility.md) — the AI coding tools we have tested Desnarl with, and what we have not.
