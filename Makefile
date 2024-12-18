###$_begin-include: mk/prologue.mk
SNIPPETS=$(shell find . -maxdepth 1 -type f '(' -name '*.sh' -o -name '*.bash' ')' | sed -e 's!^./!!' )
SUBDIRS=$(shell find . -mindepth 1 -maxdepth 1 -type d ! -name .git)

dir_has_binder=$(shell [ -f binder.py ] && echo yes)
ifeq ($(dir_has_binder),yes)
BINDER=python3 $(shell readlink -f binder.py)
ASHDOC=python3 $(shell readlink -f ashdoc.py)
else
BINDER=python3 $(shell readlink -f ../binder.py)
ASHDOC=python3 $(shell readlink -f ../ashdoc.py)
endif
###$_end-include: mk/prologue.mk

help:
	@echo "Usage:"
	@echo "- make doc : generate documentation"
	@echo "- make todo : check code completeness"
	@echo "- make test : run unit tests"
	@echo "- make rebind : rebind scripts to latest snippets"
	@echo "  Sub options: make OPTS=flags rebind"
	@echo "  - OPTS=-u : unbind files"
	@echo "  - OPTS=--dry-run : do not modify files, just show what happens"
	@echo "- make make-rebind : rebind Makefile(s) to latest snippets"
	@echo "  - OPTS work the same as with rebind, however, passing option -u"
	@echo "    may lead to a non-working Makefile"
	@echo "- make rtest : recursive test"
	@echo "- make pkgs : create packaged libraries"

doc: pkg/pyus.py
	$(ASHDOC) --title='ashlib scripting API' --prune --output=docs/ashlib \
		cgilib/*.sh \
		pp/*.sh \
		*.sh
	$(ASHDOC) --title='ashlib testing API' --prune --output=docs/testlib \
		testlib/*.sh
	type pandoc && ( cd utils && $(ASHDOC) --title='Man Pages' \
				--prune --output=../docs/manpgs  \
				-DVERSION=$$(cat ../VERSION) --gdoc --no-api \
				*.sh) || echo "Install pandoc to generate man pages"
	[ ! -d docs/.venv ] && (cd docs && ./setup.sh ) || :
	docs/py make -C docs html

###$_begin-include: mk/todo.mk
todo:
	@x= ; for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e '#\$$' $$s || echo $$s))" ; done ; [ -n "$$x" ] && echo "Missing doc-block: $$x" || :
	@x= ; for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e 'xatf_init' $$s || echo $$s))" ; done ; [ -n "$$x" ] && echo "Missing unit-test: $$x" || :
	@x= ; for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e 'TODO' $$s && echo $$s))" ; done ; [ -n "$$x" ] && echo "TODO(technical-debt): $$x" || :
	@for i in $(SUBDIRS) ; do \
	  [ ! -f $$i/Makefile ] && continue ; \
	  grep -q '^todo:' $$i/Makefile || continue ; \
	  make --no-print-directory -C "$$i" todo ; \
	done
###$_end-include: mk/todo.mk
	@gh issue list || ( \
		url=$$(tr -d ' ' < .git/config | grep url= | cut -d= -f2) ; \
		owner="$$(basename "$$(dirname "$$url")")"; \
		repo="$$(basename "$$url" .git)" ; \
		gh repo set-default "$$owner/$$repo" ; \
		gh issue list || : \
	)

###$_begin-include: mk/Kyuafile.mk
Kyuafile: $(SNIPPETS)
	@(echo '-- Autogenerated file';echo 'syntax(2)';echo "test_suite('ashlib')"; \
	x=;for s in $(SNIPPETS) ; do x="$$(echo $$x $$(grep -q -e 'xatf_init' $$s && echo $$s))" ; done ; \
	for s in $$x ; do echo "atf_test_program{name='$$s'}" ; done ; \
	) > $@
###$_end-include: mk/Kyuafile.mk

test: Kyuafile
	if type kyua ; then kyua test ; fi

rebind:
	$(BINDER) -R $(OPTS) scripts docs/py

make-rebind:
	$(BINDER) -R $(OPTS) --pattern='F+Makefile' --pattern='F-*' .

###$_begin-include: mk/rtest.mk
rtest: test
	@for i in $(SUBDIRS) ; do \
	  make -C "$$i" Kyuafile >/dev/null 2>&1 || continue ; \
	  make -C "$$i" rtest ; \
	done
###$_end-include: mk/rtest.mk

pkg/ashlib.sh: $(SNIPPETS) $(shell find pp -maxdepth 1 -type f '(' -name '*.sh' -o -name '*.bash' ')' | sed -e 's!^./!!')
	###$_begin-include: mk/upx.mk
	#
	# Compressed/executable
	#
		mkdir -p $$(dirname $@) ; \
		(echo '#!/bin/sh'; \
			[ -f VERSION ] && echo "# $$(basename "$@") $$(cat VERSION)" ; \
			[ -f ../VERSION ] && echo "# $$(basename "$@") $$(cat ../VERSION)" ; \
			echo '# src: ' ; \
			echo '$^' | fmt | sed -e 's/^/#      /' ; \
			echo '#' ; \
			echo 'eval "$$( (base64 -d | gzip -d) <<'\'_EOF_\' ; \
			(for x in $^; do \
				echo '###$$_include:' $$x ; done) \
				| $(BINDER) $(OPTS) \
				| gzip -9 | base64  ; \
			echo '_EOF_' ; echo ')"' ) > $@
	###$_end-include: mk/upx.mk

pkg/cgilib.sh:
	make -C cgilib ../pkg/cgilib.sh

pkg/pyus.py: $(shell find mypylib -maxdepth 1 -type f -name '*.py' | sed -e 's!^./!!')
	mkdir -p $$(dirname $@) ; \
	(echo '#!python3'; \
		echo '###$$_include: mypylib/pyus.in.py' ) | $(BINDER) > $@


pkgs: pkg/ashlib.sh pkg/cgilib.sh pkg/pyus.py


