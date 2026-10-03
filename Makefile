# heap-buffer-overflow in sqlite3SchemaToIndex() when an eponymous virtual
# table (json_each here) is used before and after sqlite3_deserialize().
#
#   make test     # fails: ASan heap-buffer-overflow
#   make fix      # applies fix.diff to ./sqlite
#   make test     # passes
#   make unfix    # reverts fix.diff
#
# test runs repro.c twice: under AddressSanitizer, and with SQLITE_DEBUG,
# where assert( i<db->nDb ) in sqlite3SchemaToIndex() fails instead.

# Fossil check-in to test; "trunk" also works.
CHECKIN ?= 65ec11f05a

test: repro-asan repro-debug
	./repro-asan
	./repro-debug
	@echo PASS

sqlite/configure:
	mkdir -p sqlite
	curl -fsSL https://sqlite.org/src/tarball/$(CHECKIN)/sqlite.tar.gz | tar -xz -C sqlite --strip-components=1

sqlite/Makefile: sqlite/configure
	cd sqlite && ./configure --disable-tcl

# Depending on src/ makes patching a source file rebuild the amalgamation.
sqlite/sqlite3.c: sqlite/Makefile $(wildcard sqlite/src/*)
	$(MAKE) -C sqlite sqlite3.c

repro-asan: repro.c sqlite/sqlite3.c
	$(CC) -g -fsanitize=address -Isqlite -o $@ repro.c sqlite/sqlite3.c -lm

repro-debug: repro.c sqlite/sqlite3.c
	$(CC) -g -DSQLITE_DEBUG -Isqlite -o $@ repro.c sqlite/sqlite3.c -lm

# Apply or revert fix.diff in ./sqlite. Running either twice is a no-op.
fix: sqlite/configure
	patch -d sqlite -p1 -R -f -s --dry-run < fix.diff >/dev/null || patch -d sqlite -p1 < fix.diff

unfix: sqlite/configure
	patch -d sqlite -p1 -f -s --dry-run < fix.diff >/dev/null || patch -d sqlite -p1 -R < fix.diff

clean:
	rm -rf sqlite repro-asan repro-debug

.PHONY: test fix unfix clean
