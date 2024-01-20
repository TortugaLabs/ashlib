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
