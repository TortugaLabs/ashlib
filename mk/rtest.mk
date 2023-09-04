rtest: test
	@for i in $(SUBDIRS) ; do \
	  make -C "$$i" Kyuafile >/dev/null 2>&1 || continue ; \
	  make -C "$$i" rtest ; \
	done
