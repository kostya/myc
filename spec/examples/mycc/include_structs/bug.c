#include "bug.h"

int main() {
  struct Bla bla = {0};
  test();
  bla.Inner.a = 10;
  printf("1 %d\n", bla.Inner.a);
  return 0;
}
