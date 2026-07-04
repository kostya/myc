#include <stdbool.h>

bool check1(bool x, bool y) { return (x == y) && (x != y); }

int check2(const void *a, const void *b) {
  int ia = *(const int *)a;
  int ib = *(const int *)b;
  return (ia > ib) - (ia < ib);
}

int main() {
  printf("check1 = %d\n", check1(true, false));

  int a = 45;
  int b = 34;
  printf("check2 = %d\n", check2(&a, &b));
  return 0;
}
