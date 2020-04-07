SHARDS ::= shards
BATS ::= bats

.PHONY: all
all:
	$(BATS) integration_test.bats

.PHONY: update
update:
	for i in $(find . -maxdepth 1 -mindepth 1 -type d); do
	  pushd $i
	    $(SHARDS) update
	  popd
	done
