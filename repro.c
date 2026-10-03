#include "sqlite3.h"
int main(void){
  sqlite3 *db;
  sqlite3_int64 sz;
  unsigned char *img;
  int rc;
  sqlite3_open(":memory:", &db);
  sqlite3_exec(db, "CREATE TABLE t(x); SELECT * FROM json_each('[1]');", 0, 0, 0);
  img = sqlite3_serialize(db, "main", &sz, 0);
  sqlite3_deserialize(db, "main", img, sz, sz, SQLITE_DESERIALIZE_FREEONCLOSE);
  rc = sqlite3_exec(db, "SELECT * FROM json_each('[1]');", 0, 0, 0);
  sqlite3_close(db);
  return rc;
}
