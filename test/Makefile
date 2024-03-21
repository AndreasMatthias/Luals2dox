TEST_FILES = $(wildcard var/* func/* enum/* class/*)

PROJ_FILES = ../src/luals2dox/*.lua

export LUA_PATH := ../src/?/init.lua;../src/?.lua;$(LUA_PATH)

.PHONY:test
test: test-render.run test-unknown.run test-cli.run
	$(MAKE) coverage-emacs

%.run: %.lua $(TEST_FILES) $(PROJ_FILES) json/doc.json
	$(color_blue)
	@echo -e 'Running $*.lua ...'
	$(color_default)
	lua $< $(busted_args)
	@touch $@

json/doc.json: $(TEST_FILES)
	@rm -f ./doc.json
	lua-language-server --doc ./ --doc_out_path ./
	@cp ./doc.json json/
	@rm ./doc.md

xox:
	ls -lrt $(TEST_FILES)

busted_args := --coverage --exclude-tags='skip'
ifdef TESTS
busted_args += --filter="$(TESTS)"
endif
ifdef OUTPUT
busted_args += --output=$(OUTPUT)
else
busted_args += --output='htest'
endif

.PHONY: coverage coverage-emacs coverage-report
coverage-emacs:
	@luacov-coveralls --dryrun \
		--output ../coverage-final.json > /dev/null

coverage: coverage-report
coverage-report:
	@luacov-console ../
	$(color_blue)
	@echo "======================================================================"
	@echo "Summary:  $(parent_dir_rel)"
	@echo "======================================================================"
	$(color_default)
	@luacov-console -s | tail -n +5
	$(color_blue)
	@echo "======================================================================"
	$(color_default)


.PHONY: clean distclean
clean:
	rm -f doc.json doc.md
	rm -f test-render.run test-cli.run test-unknown.run
	rm -f luacov.stats.out luacov.report.out luacov.report.out.index
distclean: clean

color_blue = @echo -en '\e[0;34m'
color_blue_bold = @echo -en '\e[1;34m'
color_default = @echo -en '\e[0m'
