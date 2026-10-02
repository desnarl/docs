---
sidebar_position: 2
title: The savings report
---

# The savings report

Desnarl keeps a plain Markdown report of what it has done for each workspace it has served. It is a local file, regenerated after every tool call, so you can open it at any time without running anything.

:::note Scope of this page
This page covers only the savings report. It does not describe the rest of the files Desnarl keeps on disk. The report's own file name, `savings-audit-report.md`, is the only name you need here.
:::

## Where the report is

The report is `savings-audit-report.md`, in the instance's **state directory**.

**The server prints that directory on stderr every time it starts**, as a line beginning `crossrepograph: state directory:`. That is the quickest way to find it. Run the server from a terminal and read the line, or look in your MCP client's server log if it keeps one.

Many MCP clients do not show a server's stderr. If yours does not, make the location a fixed one you chose: set `CROSSREPOGRAPH_STATE_DIR` to an absolute path in the `env` block of the server's MCP configuration, next to the license key, and the report will be at `<that path>/savings-audit-report.md`.

```json
"env": {
  "CROSSREPOGRAPH_LICENSE_KEY": "crg_your-license-key",
  "CROSSREPOGRAPH_STATE_DIR": "/absolute/path/to/desnarl-state"
}
```

If you do not set it, Desnarl picks a per-workspace default under your operating system's user-data directory, so two workspaces never share one report:

| OS | Default location |
|---|---|
| macOS | `~/Library/Application Support/crossrepograph/<workspace-name>-<hash>/` |
| Linux | `$XDG_STATE_HOME/crossrepograph/<workspace-name>-<hash>/`, or `~/.local/state/crossrepograph/<workspace-name>-<hash>/` when `XDG_STATE_HOME` is unset |
| Windows | `%LOCALAPPDATA%\crossrepograph\<workspace-name>-<hash>\` |

`<hash>` is derived from the workspace's real path, so you cannot work it out by hand. List the parent directory and look for the folder that starts with your workspace's name. Moving or renaming a workspace changes its hash and starts a new, empty report. In the Docker image the state directory is `/state`, which the image declares as a volume; mount it to keep the report.

## What a report contains

A report opens with a **Summary** (per-tool totals and an overall dollar range), then a **Raw data** section, then one block per workspace. The workspace block is the part to read first.

```markdown
## Workspace: my-workspace (e32208a3c0ab)

Status: Active

Edges by kind:
- importExport: 3
- schema: not measured
- deployment: not measured
- cicd: not measured
- topic: not measured

Repos by language:
- typescript: 3

Tokens saved: 48,734
Estimated $ saved: $0.10–$0.49
Time saved: not available

Calls by tool:
- crossrepo_impact: 1 call(s)
- Empty, confident: 0
- Empty, unconfirmed: 0
Total calls: 1
```

The block title is the workspace's folder name and a short hash of its path. Each block carries four figures:

1. **Edges by kind.** How many cross-repo links Desnarl found, split into import/export, schema, deployment, CI and topic.
2. **Repos by language.** How many repos in the workspace use each language.
3. **Tokens saved and dollars saved**, shown separately from time saved.
4. **Calls made**, per tool.

### Reading the status line

The `Status` line says whether a low or zero figure is a problem.

| Status | What it means |
|---|---|
| **Not applicable: no cross-repo edges** | The workspace has no cross-repo links, so there is nothing for an AI coding agent to look up. Zero savings is the honest answer, not a fault. |
| **Applicable but unused** | The workspace has cross-repo links but no calls have been made. Your agent is not reaching for the tools. Check that its instructions mention them. |
| **Active** | There are cross-repo links and calls have been made. |
| **Unknown: edges not measured** | Desnarl has not yet recorded an edge count for this workspace, so it cannot tell which of the above applies. |

### Not measured is not zero

An edge kind that reads **not measured** has not been counted yet. It does not mean there are none. Today only `crossrepo_impact` records an edge count; schema, deployment, CI and topic counts stay "not measured" until their own tools do. `crossrepo_consumers` still counts as a call.

### Empty results are credited zero

A call that finds no consumers counts toward **Calls**, but it adds **nothing** to tokens or dollars saved. The report separates two cases:

- **Empty, confident.** Nothing was found and every sibling repo was read.
- **Empty, unconfirmed.** Nothing was found, but some sibling repos were missing or could not be resolved, so the answer may be incomplete.

Neither earns a saving. The totals are deliberately conservative.

## Time saved

**Time saved currently reads "not available" in every report.** Desnarl does not yet have a source for it. The report shows token and dollar estimates only, and you should not treat the report as evidence of time saved.

## How to read the dollar figure

The dollar amount is an **illustrative equivalent-API-cost estimate, not linked to any subscription or billing.** It is not what you paid and not a quote of what you would save on any plan.

- It is a **range**, not a single number. The MCP protocol does not tell Desnarl which model your agent is using, so the range runs from the cheapest to the most expensive of the latest model families.
- It prices **input tokens only**, because the saving is context your agent did not have to read.
- It uses a **fixed pricing snapshot**, cited at the foot of the Summary with its source and date. Desnarl does not look up live prices, so the figure drifts as published pricing changes. Check the snapshot date before you rely on it.

The token figure comes from a calibrated average for each kind of call, not from a measurement of your own agent's behaviour. Treat the report as an estimate you can audit, never as a billing input.

## Privacy

The report is written to your own disk and reading it needs no network access. It contains repo names and counts, so treat it like any other file from your workspace before you share it.
