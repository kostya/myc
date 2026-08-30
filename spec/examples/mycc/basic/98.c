#include <math.h>
int printf(const char *fmt, ...);

int main() {
  printf("%f %f %f %f %f\n", INFINITY, -INFINITY, NAN, -NAN, HUGE_VAL);
  return 0;
}
