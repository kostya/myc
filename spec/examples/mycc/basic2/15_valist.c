#include <stdarg.h>
#include <stdio.h>

int sum(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int s = 0;
  for (int i = 0; i < n; i++)
    s += va_arg(ap, int);
  va_end(ap);
  return s;
}

int main(void) {
  printf("%d\n", sum(3, 10, 20, 30));
  return 0;
}
