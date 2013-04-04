DIFF?=git --no-pager diff --ignore-all-space --color-words --no-index
NOTIFY?=./bin/notify --directory ./___

.PHONY: test

test: 
	$(MAKE) _init 

test_pass:
	DIFF=cp $(MAKE) test

_init:
	-rm -rf ./___
	$(NOTIFY) init | tee /tmp/$@
	$(DIFF) /tmp/$@ test/expected/$@
