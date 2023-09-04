#
# Compressed/executable
#
	mkdir -p $$(dirname $@) ; \
	(echo '#!/bin/sh'; \
		[ -f VERSION ] && echo "# v$$(cat VERSION)" || \
		[ -f ../VERSION ] && echo "# v$$(cat ../VERSION)" ; \
		echo '# src: $^'; \
		echo 'eval "$$( (base64 -d | gzip -d) <<'\'_EOF_\' ; \
		(for x in $^; do \
			echo '###$$_include:' $$x ; done) \
			| $(BINDER) $(OPTS) \
			| gzip -9 | base64  ; \
		echo '_EOF_' ; echo ')"' ) > $@
