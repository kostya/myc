int printf(const char *fmt, ...);
#include <stdarg.h>

int sum_recursive(int n, va_list ap) {
  if (n == 0) {
    return 0;
  }
  int x = va_arg(ap, int);
  return x + sum_recursive(n - 1, ap);
}

int sum(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int s = sum_recursive(n, ap);
  va_end(ap);
  return s;
}

va_list identity_va(va_list ap) { return ap; }

int head(va_list ap) { return va_arg(ap, int); }

int tail_sum(int n, va_list ap) {
  va_arg(ap, int);
  return sum_recursive(n - 1, ap);
}

int complex(int n, ...) {
  va_list ap;
  va_start(ap, n);

  int first = head(ap);
  va_list ap2;
  va_copy(ap2, ap);
  int rest = sum_recursive(n - 1, ap2);
  va_end(ap2);

  va_end(ap);
  return first + rest;
}

int main(void) {
  printf("recursive: %d\n", sum(5, 1, 2, 3, 4, 5));
  printf("complex: %d\n", complex(5, 1, 2, 3, 4, 5));
  return 0;
}
