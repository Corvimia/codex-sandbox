CONTEXT_DOCKERFILE=contexts/android/Dockerfile
TOOLS_DIR=$(CURDIR)/volumes/tools/android
TOOLS_UPDATE_IMAGE=node:24-bookworm
TOOLS_UPDATE_CMD=npm install --package-lock-only
