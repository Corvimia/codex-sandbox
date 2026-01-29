# Codex Sandbox

This repo provides a Docker-based sandbox for running Codex with persisted workspaces and authentication, plus helper Make targets to clone, run commands, and run Codex against multiple repos.

## Installation

1. Run setup:
   - `make setup`

## Environment

Set these before running `make` commands:
- `export CODEX_ORG=your-org`

## SSH Authentication (Required)

GitHub access is SSH-only in this setup:
1. Create an SSH key under `./volumes/sshconfig` (for example `id_ed25519`).
2. Add the public key to GitHub (Settings → SSH and GPG keys).
3. Ensure the key and folder permissions are restrictive (`chmod 700 ./volumes/sshconfig` and `chmod 600` for private keys).

The container mounts `./volumes/sshconfig` to `/home/sandbox/.ssh` at runtime.

## GitHub CLI Authentication (Optional)

If you use `gh`, its config (including `hosts.yml`) is persisted by mounting `./volumes/ghconfig` to `/home/sandbox/.config/gh`. The setup script will run `gh auth login` if `hosts.yml` is missing.

## Codex Config

Codex config persists at `./volumes/codex-config/config.toml` and is mounted to `/home/sandbox/.codex/config.toml`. The setup script creates a default profile named `full_access`, and `make codex` uses that profile by default.

## Tooling (npm CLIs)

CLI tools are managed via `./volumes/tools/package.json` and `./volumes/tools/pnpm-lock.yaml`, then installed into `/opt/tools` during the image build. The container adds `/opt/tools/node_modules/.bin` to `PATH` for the `sandbox` user.

Upgrade tool versions and rebuild the image:
- `make upgrade-tools`

## Usage

Clone a repo into the shared workspace volume:
- `make clone ORG=your-org REPO=your-repo`

Run a one-off command in the container:
- `make run ls -la /workspace`

Create a fresh session, clone repos, build, and start Codex:
- `make codex repo-main repo-extra-1 repo-extra-2`

Clean up a session folder:
- `make codex-clean <session-id>`

Clean up all session folders (preserves config):
- `make codex-clean-all`

Session folders are stored under `./volumes/workspaces`.

## Note

We tried using `container`, but hit too many network-related issues (DNS resolution failures). The setup now uses Docker only.

## Troubleshooting

- If `make build` fails on `apt-get update` with DNS errors, check Docker's DNS configuration (daemon.json) and ensure macOS has a valid DNS resolver configured.
