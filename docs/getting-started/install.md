---
sidebar_position: 1
title: Install
---

# Install

**Requirements:** Node.js >= 24.

```bash
npm install
npm run build
```

This produces `dist/mcp/index.js` — the stdio MCP server entry point.

:::caution Distribution channel not finalized
This section documents the source build (clone → `npm install` → `npm run build`), which is what's confirmed working today. A packaged distribution (npm package, container image, or GitHub release) is not yet decided — this page will be updated once it is. Don't build tooling against an assumed package name or image tag; none is official yet.
:::

## License key

Desnarl will not start without a license key, even for non-commercial use. Set it in the `CROSSREPOGRAPH_LICENSE_KEY` environment variable. The key must be `crg_` followed by exactly 32 lowercase letters or digits. The check is on the format only and runs offline: it makes no network call.

Keys are issued from your account at [desnarl.com](https://desnarl.com). If the variable is missing or malformed, the server exits at startup with an error that names it, before it opens any connection.

## Add it to your MCP client

Point it at the workspace root directory that contains your sibling repos as immediate subdirectories:

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

## Restarting after an update

If you already have a connected MCP session open when Desnarl's code changes (a version upgrade, a config change), restart that session's connection — not just the server process — to pick up any change in tool shape.

## Next

- [Self-hosted deployment](../self-hosted/deployment.md) — ingestion auth, the network-queryable CI endpoint, storage, and staleness monitoring (built, not yet active).
- [MCP tool reference](../mcp-tools/reference.md) — what `crossrepo_impact`, `crossrepo_consumers`, and `crossrepo_schema_refs` actually return.
