#include <stdio.h>
#include <stdlib.h>

struct Bla {
  void *f1;
  void *f2;
};

struct Bla g = {malloc, free};

int main(void) {
  int *x = ((void *(*)(unsigned long long))(g.f1))(2 * sizeof(int));
  if (!x)
    return 1;
  x[0] = 0;
  x[1] = 1;
  printf("%d %d %d\n", *x, *(x + 1), x[1]);
  ((void (*)(void *))(g.f2))(x);
}
