#include "4.h"

static int glob = 42;

static int bla() { return 1; }

int main() {
  printf("bla = %d\n", bla());
  printf("glob = %d\n", glob);

  printf("second = %d\n", second());
  printf("second glob = %d\n", second_glob());
  return 0;
}
