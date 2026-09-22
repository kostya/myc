#include <stdarg.h>
#include <stdio.h>

typedef long l_mem;

long sum(int n, ...) {
  va_list argp;
  va_start(argp, n);

  l_mem s = 0;
  for (int i = 0; i < n; i++) {
    s += (l_mem)va_arg(argp, size_t);
  }

  va_end(argp);
  return s;
}

int main(void) {
  printf("%ld\n", sum(3, 10, 20, 30));
  return 0;
}
