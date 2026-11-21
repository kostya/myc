#include <math.h>
int printf(const char *fmt, ...);

int main() {
  printf("%f %f %d %d %f\n", INFINITY, -INFINITY, isnan(NAN), isnan(-NAN),
         HUGE_VAL);
  return 0;
}
