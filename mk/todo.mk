todo:
	@x= ; for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e '#\$$' $$s || echo $$s))" ; done ; [ -n "$$x" ] && echo "Missing doc-block: $$x" || :
	@x= ; for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e 'xatf_init' $$s || echo $$s))" ; done ; [ -n "$$x" ] && echo "Missing unit-test: $$x" || :
	@x= ; for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e 'TODO' $$s && echo $$s))" ; done ; [ -n "$$x" ] && echo "TODO(technical-debt): $$x" || :
	@for i in $(SUBDIRS) ; do \
	  [ ! -f $$i/Makefile ] && continue ; \
	  grep -q '^todo:' $$i/Makefile || continue ; \
	  make --no-print-directory -C "$$i" todo ; \
	done
