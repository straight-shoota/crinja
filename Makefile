-include Makefile.local # for optional local options e.g. threads

BATS ?= $(shell which bats)
CRYSTAL ?= $(shell which crystal)

.PHONY: test
test:
	$(CRYSTAL) spec

.PHONY: integration-test
integration-test:
	$(BATS) examples/integration_test.bats

docs:
	CRYSTAL_BIN=$(CRYSTAL) scripts/generate-docs.sh

.PHONY: deploy-docs
deploy-docs: docs
	curl https://raw.githubusercontent.com/straight-shoota/autodeploy-docs/master/autodeploy-docs.sh | bash

.PHONY: clean-docs
clean-docs:
	rm -rf docs
