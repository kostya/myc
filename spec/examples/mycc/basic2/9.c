#include <stdlib.h>
int printf(const char *fmt, ...);

struct Pair {
  int x, y;
};

static int test() {
  int n = 2;

  struct Pair {
    int first, second;
  };

  struct Pair *pairs = (struct Pair *)malloc(sizeof(struct Pair) * n);

  for (int i = 0; i < n; i++) {
    pairs[i].first = i + 1;
    pairs[i].second = i * 10;
  }

  printf("%d, %d, %d, %d\n", pairs->first, pairs->second, pairs[1].first,
         (*(pairs + 1)).second);

  free(pairs);
  return 0;
}

int main() { return test(); }
