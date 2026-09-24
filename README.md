# desnarl/docs

Desnarl's public documentation site — install, self-hosted deployment, MCP tool reference, licensing/pricing FAQ, troubleshooting. Built with [Docusaurus](https://docusaurus.io/) (TypeScript, classic template), deployed to GitHub Pages. See `CLAUDE.md`.

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

Generates static content into `build/`. CI runs this same command as its build-succeeds check on every PR (see `.github/workflows/ci.yml`); a separate workflow deploys `main` to GitHub Pages (`.github/workflows/deploy.yml`).
