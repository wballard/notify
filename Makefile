DIFF?=git --no-pager diff --ignore-all-space --color-words --no-index
NOTIFY?=./bin/notify --directory ./___

.PHONY: test

test:
	$(MAKE) _init _sends _throttle

test_pass:
	DIFF=cp $(MAKE) test

_init:
	-rm -rf ./___
	$(NOTIFY) init | tee /tmp/$@
	$(DIFF) /tmp/$@ test/expected/$@

_sends: _init
	$(NOTIFY) send Wballard@glgroup.com --from wballard@mailframe.net --message "Hi" --tags "yep, tag" --link "83B5AF27-5765-440D-9CE3-0DC52E1B1673" --context "./test/stuff.yaml" | tee /tmp/$@
	$(NOTIFY) send wBallard@glgroup.com --message "Hi Again" --tags "more, tag" --context "./test/stuff.yaml" | tee -a /tmp/$@
	$(NOTIFY) peek wballard@glgroup.com \
	| grep --invert-match 'when:' \
	| tee -a /tmp/$@
	$(NOTIFY) receive wballard@glgroup.com \
	| grep --invert-match 'when:' \
	| tee -a /tmp/$@
	#better not see these twice
	$(NOTIFY) receive wballard@glgroup.com | tee -a /tmp/$@
	$(NOTIFY) clear wballard@glgroup.com | tee -a /tmp/$@
	ls -aR ./___ | tee -a /tmp/$@
	$(DIFF) /tmp/$@ test/expected/$@

_throttle: _init
	$(NOTIFY) send wballard@glgroup.com --from wballard@mailframe.net --message "One"
	$(NOTIFY) send wballard@glgroup.com --from wballard@mailframe.net --message "Two"
	$(NOTIFY) receive wballard@glgroup.com \
	| grep --invert-match 'when:' \
	| tee /tmp/$@
	#will digest nothing, nothing to digest
	-$(NOTIFY) receive wballard@glgroup.com --throttle 5
	$(NOTIFY) send wballard@glgroup.com --from wballard@mailframe.net --message "Three"
	#will digest nothing, throttled
	$(NOTIFY) receive wballard@glgroup.com --throttle 5 | tee -a /tmp/$@
	$(DIFF) /tmp/$@ test/expected/$@
