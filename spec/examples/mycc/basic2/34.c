#include <stdio.h>
#include <stdlib.h>

void *(*g)(size_t) = malloc;

int main(void) {
  int *x = g(2 * sizeof *x);
  if (!x)
    return 1;
  x[0] = 0;
  x[1] = 1;
  printf("%d %d %d\n", *x, *(x + 1), x[1]);
  free(x);
}
