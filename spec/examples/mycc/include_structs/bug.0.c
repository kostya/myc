#include "bug.h"

void test() {
  struct Bla bla = {0};
  bla.Inner.a = 15;
  printf("2 %d\n", bla.Inner.a);
}
