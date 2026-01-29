CONTEXTS := ts android
CTX ?=

-include .env

# Sugar: make ts.build -> make CTX=ts build
$(CONTEXTS:%=%.%):
	@ctx="$(firstword $(subst ., ,$@))"; \
	 target="$(word 2,$(subst ., ,$@))"; \
	 $(MAKE) CTX=$$ctx $$target $(filter-out $@,$(MAKECMDGOALS))

include common/Makefile.common

ifneq ($(strip $(CTX)),)
  ifeq ($(filter $(CTX),$(CONTEXTS)),)
    $(error Unknown context: $(CTX). Expected one of: $(CONTEXTS))
  endif
  include contexts/$(CTX)/Makefile.inc
endif

.PHONY: codex-clean codex-clean-all
codex-clean: check-ctx
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

codex-clean-all: check-ctx
	@set -euo pipefail; \
	BASE_DIR="$(WORKSPACES_DIR)"; \
	if [ ! -d "$$BASE_DIR" ]; then \
	  echo "Workspaces folder not found: $$BASE_DIR"; \
	  exit 1; \
	fi; \
	for dir in "$$BASE_DIR"/*; do \
	  [ -d "$$dir" ] || continue; \
	  rm -rf "$$dir"; \
	  echo "Removed $$dir"; \
	done

.PHONY: contexts
contexts:
	@printf "%s\n" $(CONTEXTS)

%:
	@:
