#include "bug2.h"

void test() {
  struct Bla bla = {0};
  bla.a = 15;
  printf("2 %d\n", bla.a);
}
