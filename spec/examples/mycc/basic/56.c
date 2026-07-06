#include <stdio.h>
#include <string.h>

size_t *g1 = NULL;
size_t g2 = 0;

int y = 10 + 5;
int z = sizeof(int);
int *p = 0;
int *q = (int *)0;

int main() {
  g1 = &g2;
  g2 = 150;

  printf("%d %d\n", *g1, g2);

  printf("%d %d %d %d\n", y, z, (size_t)p, (size_t)q);

  return 0;
}
