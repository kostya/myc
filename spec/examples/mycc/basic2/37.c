#include <stdio.h>

int val = 42;

struct Bla {
  void *f1;
};

struct Bla g = {&val};

int main(void) {
  printf("%d\n", *(int *)g.f1);
  return 0;
}
