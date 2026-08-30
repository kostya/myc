#include <math.h>
#include <stdlib.h>

int printf(const char *fmt, ...);

int main() {
  double inf = INFINITY;
  double ninf = -INFINITY;
  double nan = NAN;
  double normal = 3.14;
  double zero = 0.0;
  char *endptr;

  printf("=== 1. CONSTANTS & MACROS ===\n");
  printf("INFINITY:       %f\n", INFINITY);
  printf("-INFINITY:      %f\n", -INFINITY);
  printf("NAN:            %f\n", NAN);
  printf("-NAN:           %f\n", -NAN);
  printf("HUGE_VAL:       %f\n", HUGE_VAL);
  printf("HUGE_VALF:      %f\n", HUGE_VALF);

  printf("=== 2. BUILTINS ===\n");
  printf("__builtin_inf:      %f\n", __builtin_inf());
  printf("__builtin_inff:     %f\n", __builtin_inff());

  printf("__builtin_huge_val: %f\n", __builtin_huge_val());
  printf("__builtin_huge_valf:%f\n", __builtin_huge_valf());

  printf("=== 3. CHECKS (isinf, isnan, isfinite, signbit) ===\n");
  printf("isinf(inf):         %d\n", isinf(inf));
  printf("isinf(-inf):        %d\n", isinf(ninf));
  printf("isinf(nan):         %d\n", isinf(nan));
  printf("isinf(3.14):        %d\n", isinf(normal));
  printf("isnan(nan):         %d\n", isnan(nan));
  printf("isnan(inf):         %d\n", isnan(inf));
  printf("isnan(3.14):        %d\n", isnan(normal));
  printf("isfinite(inf):      %d\n", isfinite(inf));
  printf("isfinite(3.14):     %d\n", isfinite(normal));
  printf("isfinite(0):        %d\n", isfinite(zero));
  printf("signbit(-inf):      %d\n", signbit(ninf));
  printf("signbit(inf):       %d\n", signbit(inf));
  printf("signbit(-0.0):      %d\n\n", signbit(-0.0));

  printf("=== 4. COMPARISONS ===\n");
  printf("inf == inf:         %d\n", inf == inf);
  printf("inf == -inf:        %d\n", inf == ninf);
  printf("inf > 1e308:        %d\n", inf > 1e308);
  printf("inf > inf:          %d\n", inf > inf);
  printf("-inf < inf:         %d\n", ninf < inf);
  printf("inf < 1e308:        %d\n", inf < 1e308);
  printf("nan == nan:         %d\n", nan == nan);
  printf("nan != nan:         %d\n", nan != nan);
  printf("nan > 0:            %d\n", nan > 0);
  printf("nan < 0:            %d\n", nan < 0);
  printf("nan == 0:           %d\n\n", nan == 0);

  printf("=== 5. ARITHMETIC ===\n");
  printf("inf + 1 =           %f\n", inf + 1);
  printf("inf + inf =         %f\n", inf + inf);
  printf("inf - inf =         %f\n", inf - inf);
  printf("inf * 0 =           %f\n", inf * 0);
  printf("inf * 2 =           %f\n", inf * 2);
  printf("inf / inf =         %f\n", inf / inf);
  printf("1 / inf =           %f\n", 1.0 / inf);
  printf("-1 / inf =          %f\n", -1.0 / inf);
  printf("inf / 0 =           %f\n", inf / zero);
  printf("(-inf) * (-inf) =   %f\n\n", ninf * ninf);

  printf("=== 6. strtod CONVERSION ===\n");
  printf("strtod(\"inf\") =      %f\n", strtod("inf", &endptr));
  printf("strtod(\"-INF\") =     %f\n", strtod("-INF", &endptr));
  printf("strtod(\"nan\") =      %f\n", strtod("nan", &endptr));
  printf("strtod(\"-NAN\") =     %f\n\n", strtod("-NAN", &endptr));

  printf("=== 7. ADDITIONAL TESTS ===\n");
  printf("0.0 / 0.0 =         %f\n", 0.0 / 0.0);
  printf("1.0 / 0.0 =         %f\n", 1.0 / 0.0);
  printf("-1.0 / 0.0 =        %f\n", -1.0 / 0.0);
  printf("sqrt(-1) =          %f\n", sqrt(-1.0));
  printf("log(0) =            %f\n", log(0.0));
  printf("exp(1000) =         %f\n", exp(1000.0));
  printf("pow(inf, 0) =       %f\n", pow(inf, 0.0));
  printf("pow(inf, -1) =      %f\n\n", pow(inf, -1.0));

  return 0;
}
