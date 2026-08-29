#include "include_union.h"
int printf(const char *fmt, ...);

void test(union Bla *bla) { bla->x = 1000000; }
