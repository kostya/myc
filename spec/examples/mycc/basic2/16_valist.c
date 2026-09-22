int printf(const char *fmt, ...);
#include <stdarg.h>

int sum_va(int n, va_list ap) {
  int s = 0;
  for (int i = 0; i < n; i++) {
    s += va_arg(ap, int);
  }
  return s;
}

int sum(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int result = sum_va(n, ap);
  va_end(ap);
  return result;
}

int main(void) {
  printf("%d\n", sum(3, 10, 20, 30));
  return 0;
}
