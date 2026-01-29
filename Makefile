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
codex-clean:
	@if [ -z "$(REPO)" ]; then \
	  echo "Usage: make codex-clean <session-id>"; \
	  exit 1; \
	fi
	@set -euo pipefail; \
	BASE_DIR="$(CURDIR)/volumes/workspaces"; \
	if [ -n "$(CTX)" ]; then \
	  TARGET_DIR="$$BASE_DIR/$(CTX)/$(REPO)"; \
	  if [ ! -d "$$TARGET_DIR" ]; then \
	    echo "Session folder not found: $$TARGET_DIR"; \
	    exit 1; \
	  fi; \
	  rm -rf "$$TARGET_DIR"; \
	  echo "Removed $$TARGET_DIR"; \
	else \
	  FOUND=0; \
	  for ctx_dir in "$$BASE_DIR"/*; do \
	    [ -d "$$ctx_dir" ] || continue; \
	    TARGET_DIR="$$ctx_dir/$(REPO)"; \
	    if [ -d "$$TARGET_DIR" ]; then \
	      rm -rf "$$TARGET_DIR"; \
	      echo "Removed $$TARGET_DIR"; \
	      FOUND=1; \
	    fi; \
	  done; \
	  if [ "$$FOUND" -eq 0 ]; then \
	    echo "Session folder not found in any context: $(REPO)"; \
	    exit 1; \
	  fi; \
	fi

codex-clean-all:
	@set -euo pipefail; \
	BASE_DIR="$(CURDIR)/volumes/workspaces"; \
	if [ -n "$(CTX)" ]; then \
	  BASE_DIR="$$BASE_DIR/$(CTX)"; \
	fi; \
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
