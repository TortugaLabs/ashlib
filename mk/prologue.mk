SNIPPETS=$(shell find . -maxdepth 1 -type f '(' -name '*.sh' -o -name '*.bash' ')' | sed -e 's!^./!!' )
SUBDIRS=$(shell find . -mindepth 1 -maxdepth 1 -type d ! -name .git)

dir_has_binder=$(shell [ -f binder.py ] && echo yes)
ifeq ($(dir_has_binder),yes)
BINDER=python3 binder.py
else
BINDER=python3 ../binder.py
endif
