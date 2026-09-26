# desnarl/docs

Desnarl's public documentation site — install, self-hosted deployment, MCP tool reference, licensing/pricing FAQ, troubleshooting. Built with [Docusaurus](https://docusaurus.io/) (TypeScript, classic template), deployed via Cloudflare Pages at [docs.desnarl.com](https://docs.desnarl.com). See `CLAUDE.md`.

## Local development

```bash
npm install
npm run start
```

Starts a local dev server; most changes reflect live without a restart.

## Build

```bash
npm run build
```

Generates static content into `build/`. CI runs this same command as its build-succeeds check on every PR (see `.github/workflows/ci.yml`). Deployment is handled by Cloudflare Pages' own GitHub integration (Workers & Pages → `desnarl-docs` in the Cloudflare dashboard) — every push to `main` triggers a production build there directly; there's no deploy step in this repo's own CI.
