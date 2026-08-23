#include <stdio.h>

int main() {
  long long n;

  (*(&n) = 42, 1);
  printf("n = %lld\n", n);

  double d = 42.5;
  if ((d >= 0) && (*(&n) = (long long)d, 1)) {
    printf("n = %lld\n", n);
  }

  int x = 0;
  int *p = &x;
  *p = 10;
  printf("x = %d\n", x);

  int *pp = &x;
  **(&pp) = 20;
  printf("x = %d\n", x);

  n = (42, 12);
  printf("n = %lld\n", n);

  n = (printf(""), 13);
  printf("n = %lld\n", n);

  double g = 0;
  g = (printf(""), 1.5);
  printf("n = %.1f\n", g);

  1;
  1.5;

  return 0;
}
