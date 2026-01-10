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

.PHONY: check-env setup build run shell codex codex-local clone clean volume-fix-perms
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
	    codex --dangerously-bypass-approvals-and-sandbox $(EXTRA_DIR_FLAGS) \
	  '

volume-fix-perms:
	docker run --rm -u 0 \
	  -v $(VOLUME):/workspace \
	  $(IMAGE) -c "chown -R sandbox:sandbox /workspace"

%:
	@:
