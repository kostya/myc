#include <stdarg.h>
#include <stdio.h>

void bla(int x, ...) {
  va_list ap;
  va_start(ap, x);
  int second = va_arg(ap, int);
  va_end(ap);
  printf("x = %d, second = %d\n", x, second);
}

void (*addr)(int, ...) = bla;

int main(void) {
  addr(1, 2, 3);
  return 0;
}
