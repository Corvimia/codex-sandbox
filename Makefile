IMAGE=codex-sandbox
VOLUME=codex-repos
CODEX_CONFIG_DIR=$(CURDIR)/volumes/codex-config
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

.PHONY: check-env setup build run shell codex codex-local codex-with-setup clone clean codex-clean codex-clean-all volume-fix-perms
.PHONY: $(LOCAL_REPO) $(LOCAL_EXTRA_REPOS)

$(LOCAL_REPO) $(LOCAL_EXTRA_REPOS):
	@:

check-env:
	@if [ -z "$(GITHUB_TOKEN)" ]; then \
	  echo "Missing required env var: GITHUB_TOKEN"; \
	  exit 1; \
	fi
	@if [ -z "$(CODEX_ORG)" ]; then \
	  echo "Missing required env var: CODEX_ORG"; \
	  exit 1; \
	fi

setup: check-env
	./scripts/setup.sh

build: check-env
	docker build -t $(IMAGE) .

run: check-env
	@if [ -n "$(RUN_CMD)" ]; then \
	  docker run -it --rm \
	    -e GITHUB_TOKEN \
	    -v $(VOLUME):/workspace \
	    -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	    $(IMAGE) -c '$(RUN_CMD)'; \
	else \
	  docker run -it --rm \
	    -e GITHUB_TOKEN \
	    -v $(VOLUME):/workspace \
	    -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	    $(IMAGE); \
	fi

shell: check-env
	docker run -it --rm \
	  -e GITHUB_TOKEN \
	  -v $(VOLUME):/workspace \
	  -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	  $(IMAGE)

clone: check-env
	docker run -it --rm \
	  -e GITHUB_TOKEN \
	  -v $(VOLUME):/workspace \
	  -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	  $(IMAGE) -c '\
	    git clone https://$$GITHUB_TOKEN@github.com/$(ORG)/$(REPO).git /workspace/$(REPO) \
	  '

codex: check-env
	@if [ -z "$(MAIN_REPO)" ]; then \
	  echo "Usage: make codex <repo1> [repo2 ...]"; \
	  exit 1; \
	fi
	docker run -it --rm \
	  -e GITHUB_TOKEN \
	  -v $(VOLUME):/workspace \
	  -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	  -w /workspace/$(MAIN_REPO) \
	  $(IMAGE) -c '\
	    git config --global url."https://$$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/" && \
	    codex --dangerously-bypass-approvals-and-sandbox $(ADD_DIR_FLAGS) \
	  '

codex-local: check-env
	@if [ -z "$(HOST_REPO)" ]; then \
	  echo "Usage: make codex-local /path/to/repo [extra-repo ...]"; \
	  exit 1; \
	fi
	docker run -it --rm \
	  -e GITHUB_TOKEN \
	  -v $(VOLUME):/workspace \
	  -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	  $(HOST_REPO_MOUNT) \
	  -w $(HOST_REPO_WORKDIR) \
	  $(IMAGE) -c '\
	    git config --global url."https://$$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/" && \
	    git config --global url."https://$$GITHUB_TOKEN@github.com/sourceful-official/photoshoot-mvp-frontend-4.git".insteadOf "git@github.com:sourceful-official/photoshoot-mvp-frontend-4.git" && \
	    codex --dangerously-bypass-approvals-and-sandbox $(EXTRA_DIR_FLAGS) \
	  '

codex-with-setup: check-env
	@if [ -z "$(MAIN_REPO)" ]; then \
	  echo "Usage: make codex-with-setup <repo1> [repo2 ...]"; \
	  exit 1; \
	fi
	@set -euo pipefail; \
	RAND_HEX="$$(printf '%04x' $$(( RANDOM % 65536 )))"; \
	SESSION_ID="$$(date +%Y%m%d-%H%M%S)-$$RAND_HEX"; \
	PROJECT_DIR="$(CURDIR)/volumes/$$SESSION_ID"; \
	echo "Session ID: $$SESSION_ID"; \
	echo "Project folder: $$PROJECT_DIR"; \
	mkdir -p "$$PROJECT_DIR"; \
	for repo in $(REPOS); do \
	  echo "Cloning $$repo..."; \
	  git clone "https://$$GITHUB_TOKEN@github.com/$(ORG)/$$repo.git" "$$PROJECT_DIR/$$repo"; \
	  DEFAULT_BRANCH="$$(cd "$$PROJECT_DIR/$$repo" && git remote show origin | sed -n 's/.*HEAD branch: //p')"; \
	  if [ -z "$$DEFAULT_BRANCH" ]; then DEFAULT_BRANCH="main"; fi; \
	  (cd "$$PROJECT_DIR/$$repo" && git checkout "$$DEFAULT_BRANCH" && git pull --ff-only origin "$$DEFAULT_BRANCH"); \
	done; \
	$(MAKE) build; \
	docker run -it --rm \
	  -e GITHUB_TOKEN \
	  -v "$$PROJECT_DIR":/workspace \
	  -v $(CODEX_CONFIG_DIR):/home/sandbox/.codex \
	  -w /workspace/$(MAIN_REPO) \
	  $(IMAGE) -c '\
	    git config --global url."https://$$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/" && \
	    codex --dangerously-bypass-approvals-and-sandbox $(ADD_DIR_FLAGS) \
	  '

codex-clean:
	@if [ -z "$(REPO)" ]; then \
	  echo "Usage: make codex-clean <session-id>"; \
	  exit 1; \
	fi
	@set -euo pipefail; \
	TARGET_DIR="$(CURDIR)/volumes/$(REPO)"; \
	if [ ! -d "$$TARGET_DIR" ]; then \
	  echo "Session folder not found: $$TARGET_DIR"; \
	  exit 1; \
	fi; \
	rm -rf "$$TARGET_DIR"; \
	echo "Removed $$TARGET_DIR"

codex-clean-all:
	@set -euo pipefail; \
	BASE_DIR="$(CURDIR)/volumes"; \
	if [ ! -d "$$BASE_DIR" ]; then \
	  echo "Volumes folder not found: $$BASE_DIR"; \
	  exit 1; \
	fi; \
	for dir in "$$BASE_DIR"/*; do \
	  [ -d "$$dir" ] || continue; \
	  case "$$(basename "$$dir")" in \
	    codex-config|gitconfig) continue ;; \
	  esac; \
	  rm -rf "$$dir"; \
	  echo "Removed $$dir"; \
	done

volume-fix-perms:
	docker run --rm -u 0 \
	  -v $(VOLUME):/workspace \
	  $(IMAGE) -c "chown -R sandbox:sandbox /workspace"

%:
	@:
