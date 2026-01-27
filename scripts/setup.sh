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
mkdir -p "${repo_root}/volumes/gitconfig"
mkdir -p "${repo_root}/volumes/ghconfig"
mkdir -p "${repo_root}/volumes/tools"
mkdir -p "${repo_root}/volumes/workspaces"
chmod 700 "${repo_root}/volumes/sshconfig"

tools_package="${repo_root}/volumes/tools/package.json"
if [[ ! -f "${tools_package}" ]]; then
  cat > "${tools_package}" <<'EOF'
{
  "name": "codex-sandbox-tools",
  "private": true,
  "devDependencies": {
    "@openai/codex": "latest",
    "pnpm": "latest"
  }
}
EOF
elif [[ ! -s "${tools_package}" ]]; then
  echo "Tools package.json exists but is empty: ${tools_package}"
fi

codex_config="${repo_root}/volumes/codex-config/config.toml"
if [[ ! -f "${codex_config}" ]]; then
  cat > "${codex_config}" <<'EOF'
# Codex config (user-maintained)

[profiles.full_access]
approval_policy = "never"
sandbox_mode = "danger-full-access"
EOF
elif [[ ! -s "${codex_config}" ]]; then
  echo "Codex config exists but is empty: ${codex_config}"
fi

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

git_config="${repo_root}/volumes/gitconfig/.gitconfig"
if [[ ! -f "${git_config}" ]]; then
  echo "Creating git config at ${git_config}"
  read -r -p "Git user.name: " git_user_name
  read -r -p "Git user.email: " git_user_email
  cat > "${git_config}" <<EOF
[user]
  name = ${git_user_name}
  email = ${git_user_email}
EOF
elif [[ ! -s "${git_config}" ]]; then
  echo "Git config exists but is empty: ${git_config}"
fi

echo "Building image..."
tools_lockfile="${repo_root}/volumes/tools/pnpm-lock.yaml"
if [[ ! -f "${tools_lockfile}" ]]; then
  make -C "${repo_root}" upgrade-tools
else
  make -C "${repo_root}" build
fi

echo "Fixing volume permissions..."
make -C "${repo_root}" volume-fix-perms

if [[ -s "${repo_root}/volumes/codex-config/auth.json" ]]; then
  echo "Codex already authenticated. Skipping login."
else
  echo "Starting Codex device login..."
  make -C "${repo_root}" run RUN_CMD="codex auth login --device-auth"
fi

echo "Checking GitHub CLI authentication..."
if make -C "${repo_root}" run RUN_CMD="gh auth status -h github.com" >/dev/null 2>&1; then
  echo "GitHub CLI already authenticated. Skipping login."
else
  echo "Starting GitHub CLI login..."
  make -C "${repo_root}" run RUN_CMD="gh auth login"
fi

echo "Setup complete."
