TEST_FILES = $(wildcard var/* func/* enum/* class/*)

PROJ_FILES = ../src/luals2dox/*.lua

export LUA_PATH := ../src/?/init.lua;../src/?.lua;$(LUA_PATH)

.PHONY:test
test: test-render.run test-unknown.run test-cli.run
	$(MAKE) coverage-emacs

%.run: %.lua $(TEST_FILES) $(PROJ_FILES) json/doc.json
	$(call echo_blue,'Running $*.lua ...')
	lua $< $(busted_args)
	@touch $@

json/doc.json: $(TEST_FILES)
	@rm -f ./doc.json
	lua-language-server --doc . --doc_out_path .
	@cp ./doc.json json/
	@rm ./doc.md

busted_args := --coverage --exclude-tags='skip'
ifdef TESTS
busted_args += --filter="$(TESTS)"
endif
ifdef OUTPUT
busted_args += --output=$(OUTPUT)
else
busted_args += --output='htest'
#busted_args += --output='utfTerminal' --Xoutput="--color"
endif

.PHONY: coverage coverage-emacs coverage-report
coverage-emacs:
ifneq ($(OS),Windows_NT)
	luacov-coveralls --dryrun \
		--output ../coverage-final.json > /dev/null
endif

coverage: coverage-report
coverage-report:
	$(luacov-console) ..
	$(call echo_blue,"======================================================================")
	$(call echo_blue,"Summary:  $(parent_dir_rel)")
	$(call echo_blue,"======================================================================")
	$(luacov-console) -s | tail -n +5
	$(call echo_blue,"======================================================================")


.PHONY: clean distclean
clean:
	rm -f doc.json doc.md json/doc.json
	rm -f test-render.run test-cli.run test-unknown.run
	rm -f luacov.stats.out luacov.report.out luacov.report.out.index
distclean: clean

define echo_blue
	@echo [34m$(1)[0m
endef

ifeq ($(OS),Windows_NT)
  luacov-console := cmd //c luacov-console.bat
  luacov-coveralls := cmd //c luacov-coveralls.bat
  MAKE := make.exe
else
  luacov-console := luacov-console
  luacov-coveralls := luacov-coveralls
endif
