CONTEXT_DOCKERFILE=contexts/ts/Dockerfile
TOOLS_DIR=$(CURDIR)/volumes/tools/ts
TOOLS_UPDATE_IMAGE=node:24-bookworm
TOOLS_UPDATE_CMD=corepack enable; corepack prepare pnpm@latest --activate; pnpm install --lockfile-only

ifneq (,$(wildcard .env))
include .env
endif
export

REQUIRED_ENV_VARS=CODEX_ORG
REQUIRED_ENV_PROMPT_CODEX_ORG=GitHub org (CODEX_ORG). Enter value:

check-org:
	@set -e; \
	for var in $(REQUIRED_ENV_VARS); do \
	  eval "val=\$$$${var}"; \
	  if [ -z "$$val" ]; then \
	    prompt_var="REQUIRED_ENV_PROMPT_$$var"; \
	    eval "prompt=\$${$${prompt_var}:-Missing required env var $$var. Enter value: }"; \
	    printf '%s ' "$$prompt"; \
	    read -r INPUT; \
	    if [ -z "$$INPUT" ]; then \
	      echo "$$var is required."; \
	      exit 1; \
	    fi; \
	    if [ -f .env ]; then \
	      awk -v k="$$var" -v v="$$INPUT" 'BEGIN{done=0} $$0 ~ "^" k "=" {print k "=" v; done=1; next} {print} END{if(!done) print k "=" v}' .env > .env.tmp; \
	      mv .env.tmp .env; \
	    else \
	      printf '%s=%s\n' "$$var" "$$INPUT" > .env; \
	    fi; \
	    export "$$var=$$INPUT"; \
	  fi; \
	done
