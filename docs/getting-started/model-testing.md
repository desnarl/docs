---
sidebar_position: 3
title: What we have tested with models
---

# What we have tested with models

[Client compatibility](./compatibility.md) says whether a client can start Desnarl and call its tools. This page covers a different question: given the tools, does a model use them sensibly and report the result accurately? Here is what we ran on a synthetic workspace, what we ran on real open-source code, how it was scored, and what we have not run.

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

## Real code

These runs used real open-source code instead of the synthetic workspace. They are a separate measurement from the one above: different workspaces, different scenarios, different Claude Code version. They are not a ranking, and they do not say that any model "works with" Desnarl.

### What was run

| Item | Value |
|---|---|
| Client | Claude Code 2.1.294, run headless |
| Models | Haiku, Sonnet 5.5, Opus 5.5 (host-reported IDs `claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5`) |
| Run date | 2026-10-08 (the tool-only pass below: 2026-10-07) |
| Workspaces | 8 workspaces made of 67 open-source repos, each repo pinned to a recorded commit. TypeScript: Anthropic SDK (4 repos), Stripe samples (16), OpenAI samples (14), Temporal samples (8). Go: Kubernetes (6), Prometheus (7), NATS (5), Charm (7) |
| Scenarios | Only 2 of the 10: scenario 2 (who consumes a shared package, and whether version ranges conflict) on every workspace, and scenario 1 (impact of changing an exported symbol) on Kubernetes and NATS |
| Repeats | Haiku and Sonnet 3 per cell. Opus 1 per cell, except the Anthropic SDK workspace, where it ran 3 |

**The Haiku here is not the Haiku 4.5 in the synthetic table above. Do not compare the two.** Opus ran fewer repeats than the 3 we planned, so its cells are partial, not full. Each run used a fresh copy of the workspace, registry resolution switched off, and no network access to the repos. The expected answers were read from the code by grep and manual reading, without running Desnarl's tools.

We did not run scenarios 3 to 10 on real code. Scenarios 3 and 4 have nothing to find in these repos, scenarios 6 to 9 do not depend on the code base, and scenarios 5 and 10 need facts that come from the tools rather than from the code.

72 runs produced an answer. A further 4 Haiku runs hung when the client's own call to the model API failed repeatedly. They produced no result and are not counted; they were re-run.

### Results

Runs passed out of runs made, per cell. "Passed" means the scorer's key was satisfied.

| Workspace, scenario | Haiku | Sonnet 5.5 | Opus 5.5 | What the tool returned |
|---|---|---|---|---|
| Kubernetes, 1 | 3 of 3 | 3 of 3 | 1 of 1 | Correct consumers |
| NATS, 1 | 3 of 3 | 3 of 3 | 1 of 1 | Correct consumers |
| Anthropic SDK, 2 | 0 of 3 | 0 of 3 | 0 of 3 | No consumers found |
| Stripe, 2 | 0 of 3 | 0 of 3 | 0 of 1 | No consumers found |
| OpenAI, 2 | 0 of 3 | 0 of 3 | 0 of 1 | No consumers found |
| Temporal, 2 | 0 of 3 | 0 of 3 | 0 of 1 | No consumers found |
| Kubernetes, 2 | 0 of 3 | 2 of 3 (see below) | 0 of 1 | A response of about 203,000 characters, too large for the client |
| Prometheus, 2 | 0 of 3 | 0 of 3 | 0 of 1 | A response of about 62,000 characters, too large for the client |
| NATS, 2 | 0 of 3 | 0 of 3 | 0 of 1 | Correct consumers, no Go version numbers |
| Charm, 2 | 0 of 3 | 0 of 3 | 0 of 1 | Correct consumers, no Go version numbers |

Every cell ran. Opus cells with 1 repeat are partial against the 3-repeat plan.

**Read the zeros as findings about the tools, not about the models.** Every failure reproduced on all three models, and in every one the tool's output was missing, unusable, or incomplete. We found no cell where the tool's output was correct and complete and a model answered wrongly.

- **Nothing found (Anthropic SDK, Stripe, OpenAI, Temporal).** Desnarl currently finds a repo only if it has a manifest at its root, and it could not resolve a package whose entry file is built output that a source checkout does not contain. Every TypeScript workspace returned an empty list, though the consumers exist: 3, 15, 13 and 7 repos by our count. This is a gap in what Desnarl parses. After these runs Desnarl changed in three ways, and **we have not re-run the model scenarios since**. Repos whose manifests are only in subfolders are now searched (the Anthropic workspace went from 0 to 38 consuming files, the 3 repos found). Packages built into `cjs/` or `esm/` folders are read from their source, `export =` packages and workspace negation globs are handled, and one unbuilt workspace member no longer hides the rest of its repo (Stripe went from 0 to 129 consuming files in the 15 repos we count, OpenAI from 0 to 127 in 10 of 13; the other three do not import the package by its bare name). Temporal gained a few files; the Kubernetes, Prometheus, NATS and Charm counts are unchanged except Prometheus (+13) and Charm (+53), both from Go sub-modules.
- **Response too large (Kubernetes and Prometheus, scenario 2).** For a widely imported package, `crossrepo_consumers` returned one entry per consuming file, about 203,000 characters (the Kubernetes one, in a single line) and about 62,000. That exceeds the client's output limit, so Claude Code saved it to a file that the session could not read. This was a limitation of the tool, not a failure of the model. No response in these model runs came back marked as truncated, because nothing capped the response size. After these runs, Desnarl changed how `crossrepo_consumers` responds: it now returns the complete list of consuming repos (`consumerRepos`, each with a file count and version range) and a sample of at most 50 consuming files, with `totalConsumerFiles`, `omittedConsumerFiles` and `truncated` saying when files were left out (see the [tool reference](../mcp-tools/reference.md#crossrepo_consumerspackagename)). **We have not re-run these scenarios since that change**, so we do not know whether the models now answer them. Every result on this page was measured before it.
- **No Go version data (NATS, Charm, and the version question on Kubernetes and Prometheus).** The tool did not compute version skew for Go consumers, and its description did not say so. The scorer's key expects each consumer's version, so these cells fail. The models said they could not confirm the versions because the tool did not return them. That statement is correct.

Scenario 1 on Kubernetes and NATS is the one clean comparison of model and tool, and every run there passed.

**A note on the two Sonnet passes on Kubernetes, scenario 2.** Both retried with the compact `mermaid` output format and listed the five consumers. Both also said they could not answer the version question. They are half answers that the scorer's key counts as passes, so they overstate what Sonnet did.

### What the models did with an empty or unusable result

We classified the first sentence of each answer in the 30 runs on the four TypeScript workspaces, where the tool returned no consumers (a pattern match first, then samples read by hand). These are counts from small samples.

- In 7 of 30 runs the headline stated that nothing depends on the package. All 7 mentioned a gap or caveat later in the answer.
- In 23 of 30 the headline hedged or declined.
- In 4 of 30 the model concluded that there was only one repo in the workspace, because the response reported a total of 1 repo and did not mention the repos it had skipped.
- Across the 74 runs we could map to a workspace, none claimed the versions were compatible. The 7 pattern matches were all negations, such as "I can't say whether they are compatible".
- We found no invented consumer in the answers we read in full: the whole Anthropic SDK cell and samples from Kubernetes and NATS. We did not check every run mechanically.

### Tool-only pass

Before the model runs, we called the tools directly on the same workspaces, with no model, and compared the results with the same ground truth. The tool returned the right consumers on NATS and Prometheus (the four packages asked about each) and Charm (two packages), and on Kubernetes when asked about a package path. It returned none on the four TypeScript workspaces, and none when asked about the Kubernetes module root rather than a package path. It reported no version skew on Kubernetes, Prometheus or NATS, though ground truth had it on all three. It also labelled Go test files as source files.

## What we have not run

- **Real code, beyond what is shown above.** The real-code runs covered 2 of the 10 scenarios. Scenarios 3 to 10 were not run on real code.
- **Other clients.** Codex CLI, Antigravity CLI and Grok Build are listed under [Client compatibility](./compatibility.md) as tested for connecting and calling tools. We have not run this model-behavior test with any of them.
- **Other models.** We have not run it with any model not in the table, including the models those other clients use.
- **Other platforms.** All runs were on macOS.

Where a combination does not appear in the table, we have no result for it, and its absence does not mean it passes or fails.
