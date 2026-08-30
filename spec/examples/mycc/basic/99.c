#include <math.h>
#include <stdio.h>

int main() {
  double nan = NAN;
  printf("isnan(nan): %d\n", isnan(nan));
  printf("nan == nan: %d\n", nan == nan);
  printf("nan != nan: %d\n", nan != nan);

  float nan2 = NAN;
  printf("isnan(nan): %d\n", isnan(nan2));
  printf("nan == nan: %d\n", nan2 == nan2);
  printf("nan != nan: %d\n", nan2 != nan2);

  return 0;
}
