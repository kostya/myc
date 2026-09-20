#include <stdint.h>
int printf(const char *fmt, ...);

int64_t load_count(int16_t *count) {
  int64_t n = *count;
  printf("count = %d\n", (int)n);
  return n;
}

int main() {
  int16_t cnt = 15;
  load_count(&cnt);
  return 0;
}
