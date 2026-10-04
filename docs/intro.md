---
id: intro
slug: /
title: Desnarl documentation
sidebar_position: 1
---

# Desnarl documentation

Desnarl traces impact, consumers, and schema references across every repo in your workspace — self-hosted, on your own infrastructure. In a polyrepo codebase, "what would changing this affect?" normally means grepping across every sibling checkout by hand, and easily missing a consumer that imports a symbol under a name you didn't think to search for. Desnarl answers that in one call, by resolving real import/export edges, shared `package.json` dependencies, and SQL schema references across every sibling repo checked out under your workspace root.

Because the edges are resolved by static analysis of your checked-out source rather than by a model re-reading your code each time, the same checkout gives the same answer to the same question, and every result names the consuming repo, file and import site, so you can check it by opening the file. That repeatable, inspectable answer is what makes it suitable for a CI check on a change, not only for ad hoc questions. It is a heuristic over literal names, not a proof of completeness; see below for what it does not catch.

Start with [Getting started → Install](./getting-started/install.md), then [Self-hosted deployment](./self-hosted/deployment.md) once you're ready to run Desnarl continuously against your own repos in CI.

:::note Naming: Desnarl vs. crossrepograph
"Desnarl" is the public product name. The self-hosted server underneath it keeps its original engineering name, **crossrepograph**, in a few places that are safe (and expected) to see throughout this documentation: the three MCP tool names (`crossrepo_impact`, `crossrepo_consumers`, `crossrepo_schema_refs`) and on-disk paths (`.crossrepograph/graph.db`, `.crossrepograph/query-log.jsonl`, `.crossrepograph/repos/`). That isn't inconsistent documentation — it's the actual package name, left as-is rather than renamed for the docs.
:::

## What Desnarl is not

- **Not a hosted service.** Desnarl runs entirely on infrastructure you control — see [Self-hosted deployment](./self-hosted/deployment.md) for exactly which network calls it makes and why.
- **Not real data-flow tracing.** Cross-repo resolution follows literal symbol names across a re-export chain — a genuinely useful heuristic, not a type-checker. See the [MCP tool reference](./mcp-tools/reference.md) for what that does and doesn't catch.
- **Not usage-metered or repo-count-tiered.** See the [licensing & pricing FAQ](./licensing-pricing-faq.md).
