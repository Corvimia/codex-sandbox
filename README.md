# Codex Sandbox

This repo provides a Docker-based sandbox for running Codex with persisted workspaces and authentication, plus helper Make targets to clone, shell, and run Codex against multiple repos.

## Installation

1. Run setup:
   - `make setup`

## Environment

Set these before running `make` commands:
- `export GITHUB_TOKEN=...`
- `export CODEX_ORG=your-org`

## Usage

Clone a repo into the shared workspace volume:
- `make clone ORG=your-org REPO=your-repo`

Run a one-off command in the container:
- `make run ls -la /workspace`

Start Codex with a main repo plus extra repos:
- `make codex repo-main repo-extra-1 repo-extra-2`

## Note

We tried using `container`, but hit too many network-related issues (DNS resolution failures). The setup now uses Docker only.

## Troubleshooting

- If `make build` fails on `apt-get update` with DNS errors, check Docker's DNS configuration (daemon.json) and ensure macOS has a valid DNS resolver configured.
- If `codex` exits without showing a login prompt in the container, run `codex login --device-auth` to force the device flow in the terminal.
