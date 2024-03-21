SUBDIRS := test example

.PHONY: test
test:
	$(MAKE) $@ -C test

.PHONY: coverage
coverage:
	for dir in $(SUBDIRS); do \
		$(MAKE) $@ -C $$dir; \
	done

.PHONY: doc
doc:
	lua-language-server --doc ./ --doc_out_path ./
	doxygen

.PHONY: install uninstall
install:
	rm -f doc.md
	luarocks make
uninstall:
	luarocks remove luals2dox

.PHONY: clean distclean
clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) $@ -C $$dir; \
	done
	rm -f doc.json doc.md
	rm -f coverage-final.json
	rm -rf html/
distclean: clean
	for dir in $(SUBDIRS); do \
		$(MAKE) $@ -C $$dir; \
	done
