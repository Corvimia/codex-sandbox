ifneq (,$(wildcard .env))
include .env
endif
export

REQUIRED_ENV_VARS=CODEX_ORG
REQUIRED_ENV_PROMPT_CODEX_ORG=GitHub org (CODEX_ORG). Enter value:
IMAGE=codex-sandbox
VOLUME=codex-repos
CODEX_CONFIG_DIR=$(CURDIR)/volumes/codex-config
SSH_CONFIG_DIR=$(CURDIR)/volumes/sshconfig
GIT_CONFIG_DIR=$(CURDIR)/volumes/gitconfig
GH_CONFIG_DIR=$(CURDIR)/volumes/ghconfig
WORKSPACES_DIR=$(CURDIR)/volumes/workspaces
ORG?=$(CODEX_ORG)
REPO?=$(word 2,$(MAKECMDGOALS))
REPOS?=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
LOCAL_REPO?=$(word 2,$(MAKECMDGOALS))
LOCAL_EXTRA_REPOS?=$(wordlist 3,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
MAIN_REPO?=$(word 1,$(REPOS))
ADD_DIR_FLAGS=$(foreach repo,$(wordlist 2,$(words $(REPOS)),$(REPOS)),--add-dir /workspace/$(repo))
RUN_CMD?=$(filter-out run,$(MAKECMDGOALS))
HOST_REPO?=$(LOCAL_REPO)
HOST_REPO_EXPANDED?=$(shell echo $(HOST_REPO))
HOST_REPO_NAME?=$(notdir $(HOST_REPO_EXPANDED))
HOST_REPO_MOUNT?=-v $(HOST_REPO_EXPANDED):/workspace/$(HOST_REPO_NAME)
HOST_REPO_WORKDIR?=/workspace/$(HOST_REPO_NAME)
EXTRA_REPOS?=$(LOCAL_EXTRA_REPOS)
EXTRA_DIR_FLAGS=$(foreach repo,$(EXTRA_REPOS),--add-dir /workspace/$(repo))

.PHONY: check-env setup build build-no-cache upgrade-tools run codex clone clean codex-clean codex-clean-all volume-fix-perms
.PHONY: $(LOCAL_REPO) $(LOCAL_EXTRA_REPOS)

$(LOCAL_REPO) $(LOCAL_EXTRA_REPOS):
	@:

check-env:
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

setup: check-env
	./scripts/setup.sh

build: check-env
	docker build $(if $(NO_CACHE),--no-cache,) -t $(IMAGE) .

build-no-cache: check-env
	$(MAKE) build NO_CACHE=1

upgrade-tools: check-env
	docker run --rm \
	  -v $(CURDIR)/volumes/tools:/opt/tools \
	  -w /opt/tools \
	  node:24-bookworm sh -c '\
	    corepack enable; \
	    corepack prepare pnpm@latest --activate; \
	    pnpm install --lockfile-only \
	  '
	$(MAKE) build

run: check-env
	@if [ -n "$(RUN_CMD)" ]; then \
		  docker run -it --rm \
		    -v $(VOLUME):/workspace \
		    -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
		    -v $(SSH_CONFIG_DIR):/home/sandbox/.ssh \
		    -v $(GIT_CONFIG_DIR)/.gitconfig:/home/sandbox/.gitconfig \
		    -v $(GH_CONFIG_DIR):/home/sandbox/.config/gh \
		    $(IMAGE) -c '$(RUN_CMD)'; \
	else \
		  docker run -it --rm \
		    -v $(VOLUME):/workspace \
		    -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
		    -v $(SSH_CONFIG_DIR):/home/sandbox/.ssh \
		    -v $(GIT_CONFIG_DIR)/.gitconfig:/home/sandbox/.gitconfig \
		    -v $(GH_CONFIG_DIR):/home/sandbox/.config/gh \
		    $(IMAGE); \
	fi

clone: check-env
	docker run -it --rm \
	-v $(VOLUME):/workspace \
	-v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	-v $(SSH_CONFIG_DIR):/home/sandbox/.ssh \
	-v $(GIT_CONFIG_DIR)/.gitconfig:/home/sandbox/.gitconfig \
	-v $(GH_CONFIG_DIR):/home/sandbox/.config/gh \
	$(IMAGE) -c '\
	    git clone git@github.com:$(ORG)/$(REPO).git /workspace/$(REPO) \
	  '

codex: check-env
	@if [ -z "$(MAIN_REPO)" ]; then \
	  echo "Usage: make codex <repo1> [repo2 ...]"; \
	  exit 1; \
	fi
	@set -euo pipefail; \
	RAND_HEX="$$(printf '%04x' $$(( RANDOM % 65536 )))"; \
	SESSION_ID="$$(date +%Y%m%d-%H%M%S)-$$RAND_HEX"; \
	PROJECT_DIR="$(WORKSPACES_DIR)/$$SESSION_ID"; \
	echo "Session ID: $$SESSION_ID"; \
	echo "Project folder: $$PROJECT_DIR"; \
	mkdir -p "$$PROJECT_DIR"; \
	$(MAKE) build; \
	docker run -it --rm \
	  -v "$$PROJECT_DIR":/workspace \
	  -v $(SSH_CONFIG_DIR):/home/sandbox/.ssh \
	  -v $(GIT_CONFIG_DIR)/.gitconfig:/home/sandbox/.gitconfig \
	  -v $(GH_CONFIG_DIR):/home/sandbox/.config/gh \
	  $(IMAGE) -c '\
	    KEY_FILE="$$(ls /home/sandbox/.ssh/id_ed25519 /home/sandbox/.ssh/id_rsa /home/sandbox/.ssh/* 2>/dev/null | head -n 1)"; \
	    if [ -z "$$KEY_FILE" ]; then echo "No SSH key found in /home/sandbox/.ssh"; exit 1; fi; \
	    chmod 600 "$$KEY_FILE"; \
	    ssh-keyscan github.com >> /home/sandbox/.ssh/known_hosts; \
	    for repo in $(REPOS); do \
	      echo "Cloning $$repo..."; \
	      git clone "git@github.com:$(ORG)/$$repo.git" "/workspace/$$repo"; \
	      DEFAULT_BRANCH="$$(cd "/workspace/$$repo" && git remote show origin | sed -n "s/.*HEAD branch: //p")"; \
	      if [ -z "$$DEFAULT_BRANCH" ]; then DEFAULT_BRANCH="main"; fi; \
	      (cd "/workspace/$$repo" && git checkout "$$DEFAULT_BRANCH" && git pull --ff-only origin "$$DEFAULT_BRANCH"); \
	    done \
	  '; \
	docker run -it --rm \
	-v "$$PROJECT_DIR":/workspace \
	-v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	-v $(SSH_CONFIG_DIR):/home/sandbox/.ssh \
	-v $(GIT_CONFIG_DIR)/.gitconfig:/home/sandbox/.gitconfig \
	-v $(GH_CONFIG_DIR):/home/sandbox/.config/gh \
	-w /workspace/$(MAIN_REPO) \
	$(IMAGE) -c '\
	    codex --profile full_access $(ADD_DIR_FLAGS) \
	  '

codex-clean:
	@if [ -z "$(REPO)" ]; then \
	  echo "Usage: make codex-clean <session-id>"; \
	  exit 1; \
	fi
	@set -euo pipefail; \
	TARGET_DIR="$(WORKSPACES_DIR)/$(REPO)"; \
	if [ ! -d "$$TARGET_DIR" ]; then \
	  echo "Session folder not found: $$TARGET_DIR"; \
	  exit 1; \
	fi; \
	rm -rf "$$TARGET_DIR"; \
	echo "Removed $$TARGET_DIR"

codex-clean-all:
	@set -euo pipefail; \
	BASE_DIR="$(WORKSPACES_DIR)"; \
	if [ ! -d "$$BASE_DIR" ]; then \
	  echo "Volumes folder not found: $$BASE_DIR"; \
	  exit 1; \
	fi; \
	for dir in "$$BASE_DIR"/*; do \
	  [ -d "$$dir" ] || continue; \
	  rm -rf "$$dir"; \
	  echo "Removed $$dir"; \
	done

volume-fix-perms:
	docker run --rm -u 0 \
	  -v $(VOLUME):/workspace \
	  $(IMAGE) -c "chown -R sandbox:sandbox /workspace"

%:
	@:
