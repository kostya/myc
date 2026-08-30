#include <math.h>
#include <stdio.h>

int main() {
  float f_inf = 1.0f / 0.0f;
  float f_ninf = -1.0f / 0.0f;
  float f_nan = 0.0f / 0.0f;
  float f_normal = 3.14f;

  double d_inf = 1.0 / 0.0;
  double d_ninf = -1.0 / 0.0;
  double d_nan = 0.0 / 0.0;
  double d_normal = 3.14;

  printf("=== __builtin_isinf_sign ===\n");
  printf("float +inf:  %d\n", __builtin_isinf_sign(f_inf));
  printf("float -inf:  %d\n", __builtin_isinf_sign(f_ninf));
  printf("float nan:   %d\n", __builtin_isinf_sign(f_nan));
  printf("float 3.14:  %d\n", __builtin_isinf_sign(f_normal));
  printf("double +inf: %d\n", __builtin_isinf_sign(d_inf));
  printf("double -inf: %d\n", __builtin_isinf_sign(d_ninf));
  printf("double nan:  %d\n", __builtin_isinf_sign(d_nan));
  printf("double 3.14: %d\n\n", __builtin_isinf_sign(d_normal));

  printf("=== __builtin_isfinite ===\n");
  printf("float +inf:  %d\n", __builtin_isfinite(f_inf));
  printf("float -inf:  %d\n", __builtin_isfinite(f_ninf));
  printf("float nan:   %d\n", __builtin_isfinite(f_nan));
  printf("float 3.14:  %d\n", __builtin_isfinite(f_normal));
  printf("double +inf: %d\n", __builtin_isfinite(d_inf));
  printf("double -inf: %d\n", __builtin_isfinite(d_ninf));
  printf("double nan:  %d\n", __builtin_isfinite(d_nan));
  printf("double 3.14: %d\n\n", __builtin_isfinite(d_normal));

  printf("=== __builtin_signbit ===\n");
  printf("float +inf:  %d\n", __builtin_signbit(f_inf));
  printf("float -inf:  %d\n", __builtin_signbit(f_ninf));
  printf("float 3.14:  %d\n", __builtin_signbit(f_normal));
  printf("float -3.14: %d\n", __builtin_signbit(-f_normal));
  printf("float +0.0:  %d\n", __builtin_signbit(0.0f));
  printf("float -0.0:  %d\n", __builtin_signbit(-0.0f));
  printf("double +inf: %d\n", __builtin_signbit(d_inf));
  printf("double -inf: %d\n", __builtin_signbit(d_ninf));
  printf("double 3.14: %d\n", __builtin_signbit(d_normal));
  printf("double -3.14:%d\n", __builtin_signbit(-d_normal));
  printf("double +0.0: %d\n", __builtin_signbit(0.0));
  printf("double -0.0: %d\n", __builtin_signbit(-0.0));

  return 0;
}
