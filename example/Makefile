lua-files:=$(wildcard *.lua)

html/index.html: $(lua-files)
	lua-language-server --doc ./ --doc_out_path ./
	doxygen

.PHONY: clean distclean
clean:
	rm -rf html/ latex/
distclean: clean
