int printf(const char *fmt, ...);
#include <assert.h>

int main(void) {
  int x = 10;
  assert((x == 10) && (1 < 2));
  printf("OK\n");
  return 0;
}
