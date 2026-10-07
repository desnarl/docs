---
sidebar_position: 2
title: Client compatibility
---

# Client compatibility

Desnarl is an MCP server that your AI coding tool launches. This page lists the tools we have actually run it with, what was checked, and what we have not checked yet. A client is listed as tested only when every check below passed on the version and date shown.

## Tested

| Client | Version | Tested | Notes |
|---|---|---|---|
| Claude Code | 2.1.286 | 2026-10-01 | |
| Codex CLI | 0.159.2 | 2026-10-01 | Requires approving tool calls; see [Notes](#notes). |
| Antigravity CLI (`agy`) | 1.2.14 | 2026-09-30 | |
| Grok Build (`grok`) | 1.0.44 | 2026-09-30 | |

All four clients were run on macOS. For the operating systems and install paths themselves, see [Platforms](#platforms).

## Platforms

The clients above were run on macOS. Separately, we installed the packed npm tarball into an empty directory with an empty npm cache and a fresh state directory, then started the installed `crossrepograph` command and checked that it answers an MCP `initialize` request over stdio. That is the clean-install check. It does not run a client, and it is not the source build described on the [install page](./install.md).

| Platform | Status | Evidence |
|---|---|---|
| macOS | Tested | Run locally on every release candidate; also used for all client runs above. |
| Linux (native, x64) | Tested | [Clean-install run on Ubuntu, 2026-10-07](https://github.com/desnarl/engine/actions/runs/37627145497/job/112811715698), with the tarball install and a real MCP call over stdio. |
| Docker (`node:24-trixie-slim`, x64) | Tested | [Clean-container run, 2026-10-07](https://github.com/desnarl/engine/actions/runs/37627145497/job/112811715736). The image has no compiler, so the native modules load from their prebuilt binaries. |
| Windows | Not tested | Use Docker or WSL. |
| Linux arm64 | Not tested | A prebuilt binary for one grammar package (`tree-sitter-javascript` 0.23.1) is labelled arm64 but contains an x86-64 build, so an install without a compiler fails to load on arm64. We saw this on an arm64 Docker host. |

The two run links are in a private repository, so you may not be able to open them. They were green on that date.

**Use a recent base image.** On `node:24-bookworm-slim` (Debian 12), the installed server fails to load: its tree-sitter prebuilt binary needs a newer C++ runtime than Debian 12 ships, npm falls back to compiling, and that fails without a compiler toolchain. Use a Debian 13 (trixie) based image such as `node:24-trixie-slim`, or an image with build tools (Python, make and a C++ compiler) installed.

## What "tested" means

For each client we checked that it:

1. starts the server from its own configuration and shows it as connected;
2. lists all eight [Desnarl tools](../mcp-tools/reference.md);
3. completes a real `crossrepo_consumers` call and returns the result with no error;
4. fails legibly when the license key is missing: the client connects and the user is told what to do (what each client showed is under [When the license key is missing](#missing-key));
5. still works when the client is opened on a folder that is not the Desnarl checkout.

The checks used a small sample workspace, not a large real one. The first call on a large real workspace re-reads your sibling repos and was measured at roughly 27 to 36 seconds, so a client with a short tool-call timeout could fail that first call, which the sample never triggered. Later calls are served from a local cache and took about half a second.

## Not yet tested

We have not tested the following, so we do not say whether they work: Claude Desktop, VS Code, Zed, Cursor and Windsurf. They speak MCP, which is a reason to expect them to work, not evidence that they do. This page will be updated as each is checked.

## A client is not a model

A client is the program that launches the server. The model is what decides which tool to call and how to use the answer. These results say the plumbing works in each client. They do not say that any particular model picks the right tool, asks the right question, or reports the result accurately. We have seen a model report a call as done after the call had failed. What we have run on models is on [What we have tested with models](./model-testing.md).

## Notes

### When the license key is missing {/* #missing-key */}

With a missing or malformed [license key](./install.md#license-key), Desnarl still connects and exposes a single tool, `crossrepo_license_required`, whose text tells you to set `CROSSREPOGRAPH_LICENSE_KEY`. The eight query tools do not appear. After you fix the key, restart the client.

What each client showed, re-checked on 2026-10-01 against the behavior above:

- **Claude Code 2.1.286, no key.** Connects and exposes exactly one tool, `crossrepo_license_required`.
- **Codex CLI 0.159.2, no key.** The query call did not run, and the model told the user that a valid `CROSSREPOGRAPH_LICENSE_KEY` is required. Model wording varies between runs.
- **Antigravity CLI 1.2.14, no key and malformed key.** The client connects and lists one tool; the model returned the full license-required text for both. After the key was corrected and a new session started, all eight tools were listed and a `crossrepo_consumers` call completed.
- **Grok Build 1.0.44, no key and malformed key.** `grok mcp doctor` reported a successful connection and one tool in both cases. With no key, a non-interactive call returned the full text. With a malformed key, the non-interactive call was not reliable: it hung twice and completed on the third try, and we do not know why. With a corrected key, `grok mcp doctor` listed eight tools; we did not run a call in that step.

We did not run a malformed key on Claude Code or Codex CLI. Zed and the other clients under [Not yet tested](#not-yet-tested) were not checked.

If Desnarl's tools are missing, or only `crossrepo_license_required` appears, check the license key first: that the variable is set where the client can see it, and that it is `crg_` followed by 32 lowercase letters or digits. After you fix it, restart the client. We have not shown that any client refreshes its tool list on its own, so do not rely on that.

**Antigravity CLI keeps a copy of the server's tool definitions and instructions on disk.** In one run, after a bad key and then a fix, the old license-required text stayed in its cached instructions file until a new session. We saw no effect on the later eight-tool listing or call, and we do not know whether the client passes that file to the model. Restart the client after changing the key.

### How we registered the server

The JSON on the [install page](./install.md#add-it-to-your-mcp-client) is the `mcpServers` format. Not every client uses it:

- **Claude Code** reads that JSON (`--mcp-config`).
- **Codex CLI** uses TOML: a `[mcp_servers.crossrepograph]` table in `~/.codex/config.toml` with `command`, `args` and an `env` table. To run it non-interactively, each tool call must be approved in advance, because there is nobody to ask.
- **Antigravity CLI**: `agy mcp add --env CROSSREPOGRAPH_LICENSE_KEY=<key> crossrepograph node <path-to>/dist/mcp/index.js <your-workspace>`.
- **Grok Build**: `grok mcp add --scope user --env CROSSREPOGRAPH_LICENSE_KEY=<key> crossrepograph node -- <path-to>/dist/mcp/index.js <your-workspace>`. A server added with `--scope project` is not started until that folder is trusted in an interactive session. Grok also starts any other MCP servers you have configured.

Replace `<key>` with your own license key. Client commands and file formats change between releases; if one of these no longer works, check the client's own MCP documentation.

### Gemini CLI

Google stopped serving the Gemini CLI for personal accounts on 18 June 2026 and replaced it with Antigravity CLI. We therefore test Antigravity CLI and do not list Gemini CLI.
