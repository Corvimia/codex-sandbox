ARG BASE_IMAGE=codex-sandbox-base:latest
FROM ${BASE_IMAGE}

# Install toolset (managed via volumes/tools/ts)
WORKDIR /opt/tools
COPY volumes/tools/ts/package.json volumes/tools/ts/pnpm-lock.yaml ./
RUN corepack enable \
  && corepack prepare pnpm@latest --activate \
  && pnpm install --frozen-lockfile
