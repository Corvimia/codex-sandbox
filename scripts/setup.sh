#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking Docker..."
docker info >/dev/null

echo "Creating Docker volume..."
docker volume create codex-repos >/dev/null

echo "Preparing local config directories..."
mkdir -p "${repo_root}/volumes/codex-config"
mkdir -p "${repo_root}/volumes/gitconfig"

if [[ ! -f "${HOME}/.gitconfig" ]]; then
  echo "Missing ~/.gitconfig. Configure git locally, then re-run setup."
  exit 1
fi

echo "Copying host git config into repo..."
cp "${HOME}/.gitconfig" "${repo_root}/volumes/gitconfig/.gitconfig"

echo "Building image..."
make -C "${repo_root}" build

echo "Fixing volume permissions..."
make -C "${repo_root}" volume-fix-perms

if [[ -s "${repo_root}/volumes/codex-config/auth.json" ]]; then
  echo "Codex already authenticated. Skipping login."
else
  echo "Starting Codex device login..."
  make -C "${repo_root}" run RUN_CMD="codex auth login --device-auth"
fi

echo "Setup complete."
