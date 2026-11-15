---
sidebar_position: 7
title: How the public results page is made
---

# How the public results page is made

The [results page on desnarl.com](https://desnarl.com/results) shows how often we call Desnarl on our own code and a rough estimate of the tokens that saved. This page is the method behind those figures. It says what each number is, how it is worked out, and what it is not.

The results page is **our own use, not customer data**. Desnarl does not send us your tool calls. Your own report, described on [the savings report page](./savings-report.md), stays on your disk and uses the same method.

## Measured and estimated

Every figure on the results page is labelled one of two ways.

| Label | What it covers | How it is known |
|---|---|---|
| **Measured** | Calls per tool per day, how each call ended, and edges by kind | Counted from the log Desnarl writes on every call |
| **Estimated** | Tokens saved, and the dollar figure worked out from them | Not measured on any call. Worked out from a fixed benchmark, below |

## How a call is counted

One call is one request to one Desnarl tool on our own workspace. Every call is counted, whatever its outcome, including calls to tools that earn no credit.

Each call ends in one of four outcomes:

| Outcome | Meaning | Credit |
|---|---|---|
| Credited | A non-empty answer from a tool that earns the saving credit | The mean for that tool and result size |
| Empty, confident | Nothing was found, and every sibling repo was read | 0 |
| Empty, unconfirmed | Nothing was found, but some sibling repos were missing or could not be resolved, so the answer may be incomplete | 0 |
| Errored | The query threw an error | 0 |

An empty result is never credited, so the estimate is deliberately conservative.

## Which tools are credited

Only three tools have a benchmark behind them, so only three earn the saving credit:

- `crossrepo_impact`
- `crossrepo_consumers`
- `crossrepo_schema_refs`

The other tools, `crossrepo_cicd_refs`, `crossrepo_deployment_refs` and `crossrepo_topic_refs`, are **counted and credited 0**. We do not invent a figure for a tool we have not benchmarked.

## How the token estimate is made

The estimate is a fixed mean per call, not a measurement of what any agent did.

1. **The benchmark.** Each sample is a pair. For one real cross-repo question, one leg is the tool's own cost in tokens. The other is an agent restricted to grep and file reads, answering the same question. The saving for that sample is the manual tokens minus the tool tokens. Pairing the two legs on the same question keeps the difference between easy and hard questions out of the result.
2. **The sample size.** The benchmark has **n = 21** samples. That is a small sample. We do not publish a confidence interval on the results page, and the mean should be read as a rough planning figure, not a precise one.
3. **Means by tool and result size.** Each credited tool has three means, for a low, mid and high count of results. A credited call adds the mean for its tool and the size of its result. The per-tool cut-offs and the means come from the benchmark and are fixed.
4. **The constants version.** The results page states the version of these constants it used. If the means change, the version changes, and a page covering days under more than one version says so.

The estimated tokens saved is the sum of those means over the credited calls.

### The dollar figure

The dollar figure is the estimated tokens multiplied by a model's published price per million **input** tokens. It is an illustrative equivalent-API-cost estimate, not a bill and not linked to any subscription.

- It assumes no caching and no batch discount.
- It counts input tokens only, because the saving is context an agent did not have to read.
- It shows a range, because the model an agent uses is not known to Desnarl.

The prices are a fixed snapshot of public list prices, checked on **2026-09-11**:

| Model | Input price (USD per million tokens) |
|---|---|
| Sonnet 5 | 2 |
| Opus 5 | 5 |
| Fable 5.1 | 10 |
| Mythos 5.1 | 10 |

Source: the [Anthropic pricing page](https://platform.claude.com/docs/en/about-claude/pricing). Desnarl does not look up live prices, so the figure drifts as published pricing changes. Check the date above before relying on the dollar figure.

## Route couplings

Some links between repos are found by matching an HTTP route in one repo to a call to it in another. The results page labels these **candidate couplings, unverified**. They are not part of any figure on the results page and are not added into any total. They have not been checked. This stays so until the route questions have been measured.

Calls to a route tool are counted. Their saving is **not yet measured**, so they are credited 0.

## What is left out

- **Other workspaces.** The results page covers only our own Desnarl workspace.
- **Calls with no date.** Calls recorded before October 2026 have no date. They are shown on their own line and are not in any day or in any figure.
- **Names.** The post holds totals only: dates, calls per tool, outcome counts, edges by kind, and the constants used. It has no repo names, paths or file names.

## Days with no post

Our own machine posts the totals once a day.

- A day on which it ran and found no calls shows **0**.
- A day on which no post arrived is a **gap**. We do not know what happened, and we never fill it in.
- If the last post is more than 36 hours old, the page says so and shows the date it was last updated.

## What the results page does not say

- It is one team's own use. It is not a rate for any other workspace and is not extrapolated to yours.
- We built Desnarl, so the questions we ask are the ones it was designed for.
- We do not measure what running Desnarl costs, so the figures are not net savings.
- The number of calls is small. Read it as a record of what happened, not as a rate.

## A separate check: accuracy on curated workspaces

The results page also quotes one accuracy result. It is not a rate for the calls above, and it is quoted in these exact words with all its caveats:

> 60 of 60 expected consumer repos found: 58 listed as consumers and 2 disclosed under declaredOnlyRepos; excludes 2 Stripe repos that no longer exist upstream; no false matches; repo-level, tool-only, on 8 curated workspaces (67 repos); not a general accuracy rate

`declaredOnlyRepos` lists repos whose manifest declares the package but where no import was found. That is not proof the dependency is unused.
