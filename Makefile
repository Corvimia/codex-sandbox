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

.PHONY: contexts
contexts:
	@printf "%s\n" $(CONTEXTS)

%:
	@:
