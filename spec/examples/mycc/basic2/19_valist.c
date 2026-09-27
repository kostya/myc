int printf(const char *fmt, ...);
#include <stdarg.h>

void parse_args2(va_list ap) {
  int a = va_arg(ap, int);
  char b = va_arg(ap, char);
  int *c = va_arg(ap, int *);

  printf("a = %d, b = %d, c = %d\n", a, b, *c);
}

void parse_args1(va_list ap) { parse_args2(ap); }

void check(int n, ...) {
  va_list ap;
  va_start(ap, n);
  parse_args1(ap);
  va_end(ap);
}

int main(void) {
  int c = 30;
  check(3, 10, (char)20, &c);
  return 0;
}
