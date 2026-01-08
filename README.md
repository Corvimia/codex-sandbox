# Codex Sandbox

## Installation

1. Start the container system if it is not already running:
   - `docker info`
2. Create the persistent volume:
   - `docker volume create codex-repos`
3. Create a local codex config directory (persisted at `~/.codex` in the container):
   - `mkdir -p volumes/codex-config`
4. Copy your host git config into the repo (for image builds):
   - `mkdir -p volumes/gitconfig && cp ~/.gitconfig volumes/gitconfig/.gitconfig`
5. Build the container image:
   - `make build`
6. Fix volume permissions (one-time):
   - `make volume-fix-perms`
7. Start a shell:
   - `make shell`

## Note

We tried using `container`, but hit too many network-related issues (DNS resolution failures). The setup now uses Docker only.

## Troubleshooting

- If `make build` fails on `apt-get update` with DNS errors, check Docker's DNS configuration (daemon.json) and ensure macOS has a valid DNS resolver configured.
- If `codex` exits without showing a login prompt in the container, run `codex login --device-auth` to force the device flow in the terminal.
