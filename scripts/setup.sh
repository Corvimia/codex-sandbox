#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking Docker..."
docker info >/dev/null

echo "Creating Docker volume..."
docker volume create codex-repos >/dev/null

echo "Preparing local config directories..."
mkdir -p "${repo_root}/volumes/codex-config"
mkdir -p "${repo_root}/volumes/sshconfig"
chmod 700 "${repo_root}/volumes/sshconfig"

ssh_key=""
if [[ -f "${repo_root}/volumes/sshconfig/id_ed25519" ]]; then
  ssh_key="${repo_root}/volumes/sshconfig/id_ed25519"
elif [[ -f "${repo_root}/volumes/sshconfig/id_rsa" ]]; then
  ssh_key="${repo_root}/volumes/sshconfig/id_rsa"
fi

if [[ -z "${ssh_key}" ]]; then
  echo "Missing SSH key in ${repo_root}/volumes/sshconfig (expected id_ed25519 or id_rsa)."
  exit 1
fi

chmod 600 "${ssh_key}"

ssh_config="${repo_root}/volumes/sshconfig/config"
if [[ ! -f "${ssh_config}" ]]; then
  cat > "${ssh_config}" <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile /home/sandbox/.ssh/$(basename "${ssh_key}")
  IdentitiesOnly yes
EOF
  chmod 600 "${ssh_config}"
fi

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
