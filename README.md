# sqlite-deserialize-repro

Reproduces a heap-buffer-overflow in SQLite's `sqlite3SchemaToIndex()`. It is
triggered by querying an eponymous virtual table (`json_each`, `pragma_*`,
`dbstat`, or a module registered with `sqlite3_create_module()`) before and
after `sqlite3_deserialize()` on `"main"`.

`sqlite3VtabEponymousTableInit()` stores `db->aDb[0].pSchema` in the eponymous
table once. `sqlite3_deserialize()` frees that Schema and installs a new one,
so the next query's `sqlite3SchemaToIndex()` never finds the stale pointer and
reads past the end of `db->aDb[]`.

Found while testing [@photostructure/sqlite](https://github.com/photostructure/node-sqlite).

## Run it

Needs `make`, `curl`, `tar`, `patch`, and a C compiler with AddressSanitizer.

```sh
make test     # fails: ASan heap-buffer-overflow
make fix      # applies fix.diff to ./sqlite
make test     # passes
make unfix    # reverts fix.diff
```

`make test` downloads SQLite check-in
[65ec11f05a](https://sqlite.org/src/info/65ec11f05a) (trunk, 2026-10-02) into
`./sqlite`, builds the amalgamation, and runs `repro.c` twice:

- under AddressSanitizer, which reports the overflow;
- with `-DSQLITE_DEBUG`, where `assert( i<db->nDb )` in
  `sqlite3SchemaToIndex()` fails.

To test current trunk: `make clean && make test CHECKIN=trunk`.

## Files

- `repro.c`: the reproduction.
- `fix.diff`: a candidate fix to `src/attach.c` that clears the eponymous
  tables when `sqlite3_deserialize()` reopens `main`. Offered as
  documentation of what we tried, not as a proposed patch.
- `Makefile`: the `test`, `fix`, `unfix`, and `clean` targets.

## License

[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). To the extent
possible under law, PhotoStructure Inc. has waived all copyright and related
or neighboring rights to this work.
