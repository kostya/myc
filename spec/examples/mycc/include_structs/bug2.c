#include "bug2.h"

int main() {
  struct Bla bla = {0};
  test();
  bla.a = 10;
  printf("1 %d\n", bla.a);
  return 0;
}
