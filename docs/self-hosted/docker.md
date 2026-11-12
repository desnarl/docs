---
sidebar_position: 5
title: Run the container image
---

# Run the container image

The image `ghcr.io/desnarl/crossrepograph` runs the same stdio server as the npm package. Use it on a locked-down machine or where you would rather not install Node. It is built for `linux/amd64` only.

## What the image contains

- The server as its entry point: `node dist/mcp/index.js`. It takes the workspace root as its one argument, exactly like the npm package.
- No fixed workspace. You mount your repos and pass the path **inside the container**.
- A state directory at `/state`, set through `CROSSREPOGRAPH_STATE_DIR=/state` and declared as a volume.
- The `node` user (uid 1000), not root.
- No network port. The server talks to your MCP client over stdio, so the container must run with `-i` and without `-d`.

## Run it

```sh
docker run -i --rm \
  -e CROSSREPOGRAPH_LICENSE_KEY=crg_your-license-key \
  -v /absolute/path/to/your-workspace:/workspace:ro \
  -v desnarl-state:/state \
  ghcr.io/desnarl/crossrepograph:<tag> \
  /workspace
```

- `-v ...:/workspace:ro` mounts your workspace read-only. Desnarl never writes into your repos, so read-only is safe.
- `-v desnarl-state:/state` keeps the cache and reports in a named volume. Without it they are lost when the container is removed. If you bind-mount a host folder instead, it must be writable by uid 1000.
- The last argument is the workspace path inside the container, not on your host.
- Replace `<tag>` with a release tag. The GitHub release lists the image pinned by digest; use that for repeatable runs.

To use it from an MCP client, make the container the server command:

```json
{
  "mcpServers": {
    "crossrepograph": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "CROSSREPOGRAPH_LICENSE_KEY",
        "-v", "/absolute/path/to/your-workspace:/workspace:ro",
        "-v", "desnarl-state:/state",
        "ghcr.io/desnarl/crossrepograph:<tag>",
        "/workspace"
      ],
      "env": {
        "CROSSREPOGRAPH_LICENSE_KEY": "crg_your-license-key"
      }
    }
  }
}
```

The `-e CROSSREPOGRAPH_LICENSE_KEY` with no value passes the variable from the client's `env` block through to the container, so the key is not written into the `args`.

## Things to know

- **File paths in results are container paths** (`/workspace/...`), not your host paths.
- **Docker Desktop, Colima and similar** only share certain host folders with their virtual machine. A workspace outside those folders can appear as an empty directory, and then every answer is empty. Check what your runtime shares.
- **`linux/arm64` hosts** (Apple Silicon, ARM cloud instances) get no matching image. Use the npm package there.
- **Settings** go in as `-e NAME=value`; see [Configuration](./configuration.md).
- **Not in v0.2.0:** this release has no network endpoint and no CI integration. The image is the same local stdio server, run in a container.
- **If the container exits at once**, run it from a terminal and read stderr. The usual causes are on the [troubleshooting page](../troubleshooting.md#server-does-not-start).
