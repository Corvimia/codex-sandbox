CONTEXT_DOCKERFILE=contexts/ts/Dockerfile
TOOLS_DIR=$(CURDIR)/volumes/tools/ts
TOOLS_UPDATE_IMAGE=node:24-bookworm
TOOLS_UPDATE_CMD=corepack enable; corepack prepare pnpm@latest --activate; pnpm install --lockfile-only
