#include <stdio.h>

static char base[16];

int main(void) {
  unsigned long long large = 4294967296ULL;
  unsigned int unsigned_index = 2147483648U;
  long long signed_index = -1;

  char *a = base + large;
  char *b = base + unsigned_index;
  char *c = a + signed_index;

  int ok = (a - base == 4294967296LL && b - base == 2147483648LL &&
            c - base == 4294967295LL);
  printf("%d\n", ok);
  return !ok;
}
