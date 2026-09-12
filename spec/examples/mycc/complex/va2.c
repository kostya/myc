int printf(const char *fmt, ...);
#include <stdarg.h>

struct VaHolder {
  va_list ap;
  int count;
};

void holder_init(struct VaHolder *h, int count, va_list ap) {
  va_copy(h->ap, ap);
  h->count = count;
}

int holder_sum(struct VaHolder *h) {
  int s = 0;
  for (int i = 0; i < h->count; i++) {
    s += va_arg(h->ap, int);
  }
  return s;
}

void holder_free(struct VaHolder *h) { va_end(h->ap); }

int sum(int n, ...) {
  va_list ap;
  va_start(ap, n);

  struct VaHolder h;
  holder_init(&h, n, ap);

  va_end(ap);

  int s = holder_sum(&h);
  holder_free(&h);

  return s;
}

int main(void) {
  printf("struct va: %d\n", sum(5, 1, 2, 3, 4, 5));
  return 0;
}
