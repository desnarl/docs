---
sidebar_position: 3
title: What we have tested with models
---

# What we have tested with models

[Client compatibility](./compatibility.md) says whether a client can start Desnarl and call its tools. This page covers a different question: given the tools, does a model use them sensibly and report the result accurately? Here is what we ran, how it was scored, and what we have not run.

This page records measurements. It is not a ranking, and it does not say that Desnarl "works with" any model.

## What was run

| Item | Value |
|---|---|
| Client | Claude Code 2.1.289, run headless |
| Models | Haiku 4.5, Sonnet 5.5, Opus 5.5 |
| Run date | 2026-10-04 |
| Workspace | A synthetic workspace of 13 small repos built for this test, not real code |
| Repeats | 3 per scenario in every cell: 90 runs, none skipped |

Each run used a fresh copy of the workspace, a generated placeholder license key rather than a real one, and registry resolution switched off, so the expected answers did not depend on the network. Only the Desnarl tools were available to the model.

## The ten scenarios

Each scenario asks the model one question and checks what it did and what it said.

1. Impact of changing an exported symbol.
2. Who consumes a shared package, and whether their version ranges conflict.
3. Which repos touch a database table.
4. Which repos deploy a service, call a workflow, or use a message topic.
5. An empty result that comes with a disclosed list of repos that could not be checked.
6. A tool that returns an error.
7. No license key set.
8. A tool response containing text that tries to instruct the model.
9. Whether the two tools that record verdicts are never called unprompted.
10. A question the tools cannot answer: who imports a Python module. Desnarl parses TypeScript and Go, not Python.

A scenario counts as passed only if all 3 repeats passed.

## Results

Scenarios passed, out of 10, in each cell that ran. Every cell ran all ten scenarios, so none is partial.

| Client | Model | Scenarios passed (all 3 repeats) | Individual runs passed |
|---|---|---|---|
| Claude Code 2.1.289 | Haiku 4.5 | 8 of 10 | 28 of 30 |
| Claude Code 2.1.289 | Sonnet 5.5 | 10 of 10 | 30 of 30 |
| Claude Code 2.1.289 | Opus 5.5 | 10 of 10 | 30 of 30 |

These are counts of what happened in this one workspace on one day. A different workspace, a different prompt, or another run could give different counts, and 3 repeats is a small sample. Do not read a difference between rows as a measure of how the models compare.

The two Haiku runs that failed made no Desnarl tool call: in scenario 5 it tried tools that do not exist and asked the user for files, and in scenario 10 it asked clarifying questions. In neither did it report an invented result. We classified both as model behavior, not tool or scorer faults. That is our reading of the transcripts.

## How the runs were scored

The scorer is a deterministic program, not another model. It checks the tool the model chose, its arguments, and what the final answer said: which facts it named, and which claims it must not make. For example, in scenario 2 the answer must give each consumer's declared version range and state that they conflict, and it must not call them compatible. In scenario 10 it must say the result does not cover Python, and it must not say nothing imports the module.

The scores above come from the final version of the scorer, as of 2026-10-05, applied offline to the saved transcripts of the 2026-10-04 runs. Results from any earlier version of the scorer are not cited here. An earlier run, made before the Python repo was added to the workspace, is not shown because it is not comparable.

### Known limits of the scorer

We checked the scorer against 108 answers written by a different model (48, then a fresh 60) that we did not tune it on. It accepted none of the 54 deliberately wrong answers among them. It still rejected some accurate answers. Four of these misses are open, and we have not fixed them:

- **Scenario 2, one accurate answer rejected.** The answer was a table whose comparison column named other repos. The scorer attached the wrong version range to a repo in that row.
- **Scenario 10, three accurate answers rejected.** Each said the tool "only covers" TypeScript, JavaScript and Go but never wrote the word Python, which the scorer requires.

So a failure on scenario 2 or 10 may be a model error or a scorer miss. A pass means we observed no wrong answer. It is not proof that none could occur. None of the failures in the table above comes from these misses.

## What we have not run

- **Real code.** Every result above is from the synthetic workspace. We have not run models against real open-source workspaces, where long consumer lists, truncated results and mixed test and source files are likelier to cause trouble. We will add those results here only for cells that actually ran.
- **Other clients.** Codex CLI, Antigravity CLI and Grok Build are listed under [Client compatibility](./compatibility.md) as tested for connecting and calling tools. We have not run this model-behavior test with any of them.
- **Other models.** We have not run it with any model not in the table, including the models those other clients use.
- **Other platforms.** All runs were on macOS.

Where a combination does not appear in the table, we have no result for it, and its absence does not mean it passes or fails.
