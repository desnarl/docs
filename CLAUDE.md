# desnarl/docs

Desnarl's public documentation site (Docusaurus, TypeScript classic template) — install, self-hosted deployment, MCP tool reference, licensing/pricing FAQ, troubleshooting. Public from day one, deployed via Cloudflare Pages at `docs.desnarl.com` (not GitHub Pages — moved off it deliberately; see "Hosting" below). Not a Fence product repo — Desnarl is a standalone product under the `desnarl` GitHub org. This repo has no code dependency on `crossrepo-graph` (the MCP server backend); it documents it.

## Non-negotiable rules

**No `Co-Authored-By: Claude` or any AI attribution in commits or PRs.** Never add `Co-Authored-By:`, "Generated with Claude Code", or any AI tool attribution to a commit message or PR description.

## Where the decisions behind this repo come from

The product decisions this repo documents were made in `fencedotdev/crossrepo-graph`'s `internal/checklists/checklist-phase-2.md` (see item 2.13.2 specifically for this repo's own build/content requirements) and its three Claude Design briefs (`internal/briefs/design-brief-*.md` in that repo). This repo is downstream of those decisions, not the place they're recorded — cross-reference that checklist for rationale, don't re-derive it here. See also `../CLAUDE.md` at the `desnarl/` workspace root, and `../web/CLAUDE.md` for the sibling marketing-site-plus-portal repo this site's copy needs to stay consistent with.

Load-bearing decisions carried into this repo's content — don't drift from these without checking the checklist first:

- **No email support, no public Discord support channel, ever** (checklist 2.5.9, decided 2026-09-11) — support is an in-portal ticket system that doesn't exist yet. The troubleshooting page's "Getting help" section is the one place this is easiest to get wrong; it must route readers to the in-portal ticket system only, framed as not-yet-live, never imply an email or Discord channel.
- **$25/mo is an explicit, unvalidated placeholder** (2.5.5) — never present it as a locked, final price. Carry the caveat verbatim wherever the number appears.
- **Public-facing product name is "Desnarl," not "crossrepo-graph"** (2.6.1) — `crossrepo-graph` only appears where it's factually accurate (the three MCP tool names, on-disk `.crossrepo-graph/` paths), never as the product's own name in prose.
- **Never claim "zero network calls" or "no GDPR exposure."** The correct framing is "four named network calls, two live today" (ingestion and registry resolution; the staleness alert is built but no released instance starts it, and the license check-in is not yet shipped) and "GDPR exposure reduced to standard SaaS-signup scope, not eliminated" (2.6.4/2.2.5). This has gone stale in source material before (the internal `user-guide.md` this site's content was adapted from still says "no network calls" in its Phase-1-scoped section) — verify the current shipped/unshipped split against the code (is the feature actually called from a released entrypoint?) and `checklist-phase-2.md` before repeating a network-calls claim, don't trust a single doc snapshot. "Shipped" here once meant "the module exists", which overstated the staleness alert.
- **Licensing is self-attested, not enforced or verified** (2.5.3).

## Not a service repo

This repo does **not** follow a TDD/100%-coverage/complexity-limit regime — there's no application logic here to test in that sense (matching the same exception carved out for Fence's own `fence/docs` repo). CI here is a build-succeeds check (`npm run build` + `npm run typecheck`), not a Vitest coverage gate. See `.github/workflows/ci.yml`.

## Hosting

Deployed via Cloudflare Pages (project `desnarl-docs`, in the same Cloudflare account/zone as `desnarl.com`), connected directly to this repo's GitHub source through the Cloudflare dashboard's own OAuth flow — not creatable via the plain Cloudflare API, and not GitHub Actions-driven. Build command `npm run build`, output directory `build`, production branch `main`. Custom domain: `docs.desnarl.com`.

This repo previously deployed to GitHub Pages (`organizationName`/`projectName`/`baseUrl: /docs/` in `docusaurus.config.ts`) — moved to Cloudflare on the founder's explicit instruction (2026-09-26), matching every other product in this Cloudflare account's own docs-hosting convention (`docs.<product>.com` via Cloudflare Pages). `baseUrl` is now `/` since the site is served at a domain root, not a GitHub-Pages-style project subpath — don't reintroduce a `/docs/` prefix.

`.github/workflows/ci.yml` is a PR build-check gate only, unrelated to deployment — Cloudflare's own GitHub integration builds and deploys `main` independently of this repo's own Actions.

## Content discipline

- Content is adapted from `fencedotdev/crossrepo-graph`'s `internal/user-guide.md` and `internal/handover.md`, not hand-written from scratch and left to drift from the real product. If those source docs change materially, check whether this site's content needs updating too.
- No blog. No marketing copy beyond what already lives on `desnarl/web`'s own homepage — this site is documentation only (install, self-hosted deployment, MCP tool reference, licensing/pricing FAQ, troubleshooting). Before writing new public-facing product-name or tagline copy, check `desnarl/web`'s `src/i18n/messages.ts` for the already-established terminology rather than inventing a fresh phrasing.
- Theme tokens (`src/css/custom.css`) are translated by hand from `~/Desktop/Desnarl/_ds/desnarl-design-system-*/tokens/*.css` and `~/Desktop/Desnarl/mantine-theme-mapping-brief.md` — copied in, not re-derived at build time. Re-sync by hand if the source design system changes; don't reuse Mantine/Next.js JSX values literally, they're a different stack's adapter of the same source tokens.
- No third-party font CDN — fonts are self-hosted (`src/css/fonts/*.woff2`) per the design system's own stated rationale: a site whose pitch is "nothing leaves your infrastructure" must not ping Google on every page load.

## Security

- No credentials in source code. This repo has no backend and holds no customer credentials — if that ever changes (e.g. an embedded API playground), apply the same credential-custody discipline `desnarl/web/CLAUDE.md` documents before shipping it.
- Branch protection on `main`: no direct pushes, PR required, CI must pass, signed commits required.
- **A sandbox-blocked action is a stop signal, not an obstacle.** If a git operation, tool call, or permission check is blocked, stop and report back exactly what was blocked — never reach for a different tool or mechanism (the GitHub API in place of `git`, a raw script in place of a blocked command, manually constructing commits/blobs/trees, etc.) to reproduce the same effective action a different way. The restriction exists for a reason even when it isn't obvious from where you're standing, and routing around it defeats whatever it was protecting regardless of how legitimate the underlying task is — this applies with extra force to anything touching signed commits, branch protection, or another repo's checkout.
- **Before any commit-adjacent operation (creating a branch, `git add`, `git commit`, `git checkout`), confirm the checkout is actually where you left it — `git branch --show-current` and `git status` — rather than assuming.** This `desnarl/`-style workspace's checkout can be used by more than one independent Claude Code session with no coordination beyond git's own object-level atomicity, and that atomicity does not protect against a HEAD-pointer race (confirmed the hard way in the sibling `fencedotdev` workspace this tooling was ported from — see that workspace's own `crossrepo-graph/CLAUDE.md` for the incident). When `ListAgents` shows other active sessions, prefer an isolated detached worktree (off `origin/main`, never touching the shared checkout's branch or index) for anything sensitive — a new branch, a commit — rather than operating directly in the shared checkout.
