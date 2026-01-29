# Codex Sandbox

This repo provides a Docker-based sandbox for running Codex with persisted workspaces and authentication, plus helper Make targets to clone, run commands, and run Codex against multiple repos.

## Installation

1. Run setup:
   - `CTX=ts make setup` (or `CTX=android make setup`)

## Environment

Set these before running `make` commands:
- `export CODEX_ORG=your-org`
- `export CTX=ts` (or `android`)

You can also put these in a repo root `.env` file (Make will load it).

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

Each context has its own tool manifest under `./volumes/tools/<context>/`. The `ts` context uses `pnpm-lock.yaml`, while the `android` context uses `package-lock.json`. Tools are installed into `/opt/tools` during the image build. The container adds `/opt/tools/node_modules/.bin` to `PATH` for the `sandbox` user.

Upgrade tool versions and rebuild the image:
- `make CTX=ts upgrade-tools` (or `make android.upgrade-tools`)

## Usage

Clone a repo into the shared workspace volume:
- `make CTX=ts clone ORG=your-org REPO=your-repo`

Run a one-off command in the container:
- `make CTX=ts run ls -la /workspace`

Start an interactive shell in the container:
- `make CTX=ts run`

Create a fresh session, clone repos, build, and start Codex:
- `make CTX=ts codex repo-main repo-extra-1 repo-extra-2`

Clean up a session folder:
- `make CTX=ts codex-clean <session-id>`

Clean up all session folders (preserves config):
- `make CTX=ts codex-clean-all`

Session folders are stored under `./volumes/workspaces/<context>`.

List available contexts:
- `make contexts`

Optional sugar syntax:
- `make ts.build`
- `make android.run`

## Note

We tried using `container`, but hit too many network-related issues (DNS resolution failures). The setup now uses Docker only.

## Troubleshooting

- If `make build` fails on `apt-get update` with DNS errors, check Docker's DNS configuration (daemon.json) and ensure macOS has a valid DNS resolver configured.
