#include "include_union.h"
int printf(const char *fmt, ...);

int main() {
  union Bla bla = {0};
  test(&bla);
  printf("bla.y = %d\n", bla.y);
  printf("bla.x = %d\n", bla.x);
  return 0;
}
