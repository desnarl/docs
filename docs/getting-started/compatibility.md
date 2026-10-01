---
sidebar_position: 2
title: Client compatibility
---

# Client compatibility

Desnarl is an MCP server that your AI coding tool launches. This page lists the tools we have actually run it with, what was checked, and what we have not checked yet. A client is listed as tested only when every check below passed on the version and date shown.

## Tested

| Client | Version | Tested | Notes |
|---|---|---|---|
| Claude Code | 2.1.285 | 2026-09-30 | |
| Codex CLI | 0.159.2 | 2026-09-30 | Requires approving tool calls; see [Notes](#notes). |
| Antigravity CLI (`agy`) | 1.2.14 | 2026-09-30 | |
| Grok Build (`grok`) | 1.0.44 | 2026-09-30 | |

All four were run on macOS. We have not tested Windows or Linux.

## What "tested" means

For each client we checked that it:

1. starts the server from its own configuration and shows it as connected;
2. lists all eight [Desnarl tools](../mcp-tools/reference.md);
3. completes a real `crossrepo_consumers` call and returns the result with no error;
4. shows the `crossrepo_license_required` tool when the license key is missing (not yet re-checked in any client since this behavior changed; see [below](#missing-key));
5. still works when the client is opened on a folder that is not the Desnarl checkout.

The checks used a small sample workspace, not a large real one. The first call on a large real workspace re-reads your sibling repos and was measured at roughly 27 to 36 seconds, so a client with a short tool-call timeout could fail that first call, which the sample never triggered. Later calls are served from a local cache and took about half a second.

## Not yet tested

We have not tested the following, so we do not say whether they work: Claude Desktop, VS Code, Zed, Cursor and Windsurf. They speak MCP, which is a reason to expect them to work, not evidence that they do. This page will be updated as each is checked.

## A client is not a model

A client is the program that launches the server. The model is what decides which tool to call and how to use the answer. These results say the plumbing works in each client. They do not say that any particular model picks the right tool, asks the right question, or reports the result accurately. We have seen a model report a call as done after the call had failed.

## Notes

### When the license key is missing {/* #missing-key */}

With a missing or malformed [license key](./install.md#license-key), Desnarl still connects and exposes a single tool, `crossrepo_license_required`, whose text tells you to set `CROSSREPOGRAPH_LICENSE_KEY`. The eight query tools do not appear. After you fix the key, restart the client.

We have not yet re-tested each client against this behavior. Earlier results, from before it existed, showed some clients reporting a failed start with no reason and others showing nothing at all, so what each client displays now may differ and is not documented here until it is checked. If Desnarl's tools are missing, or only `crossrepo_license_required` appears, check the license key first: that the variable is set where the client can see it, and that it is `crg_` followed by 32 lowercase letters or digits.

### How we registered the server

The JSON on the [install page](./install.md#add-it-to-your-mcp-client) is the `mcpServers` format. Not every client uses it:

- **Claude Code** reads that JSON (`--mcp-config`).
- **Codex CLI** uses TOML: a `[mcp_servers.crossrepograph]` table in `~/.codex/config.toml` with `command`, `args` and an `env` table. To run it non-interactively, each tool call must be approved in advance, because there is nobody to ask.
- **Antigravity CLI**: `agy mcp add --env CROSSREPOGRAPH_LICENSE_KEY=<key> crossrepograph node <path-to>/dist/mcp/index.js <your-workspace>`.
- **Grok Build**: `grok mcp add --scope user --env CROSSREPOGRAPH_LICENSE_KEY=<key> crossrepograph node -- <path-to>/dist/mcp/index.js <your-workspace>`. A server added with `--scope project` is not started until that folder is trusted in an interactive session. Grok also starts any other MCP servers you have configured.

Replace `<key>` with your own license key. Client commands and file formats change between releases; if one of these no longer works, check the client's own MCP documentation.

### Gemini CLI

Google stopped serving the Gemini CLI for personal accounts on 18 June 2026 and replaced it with Antigravity CLI. We therefore test Antigravity CLI and do not list Gemini CLI.
