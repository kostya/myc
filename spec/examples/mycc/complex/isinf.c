int printf(const char *fmt, ...);

int main() {
  double inf = 1.0 / 0.0;
  double ninf = -1.0 / 0.0;
  double nan = 0.0 / 0.0;
  double normal = 1.0;
  double zero = 0.0;

  printf("=== isinf ===\n");
  printf("isinf(+inf) = %d\n", __builtin_isinf(inf));
  printf("isinf(-inf) = %d\n", __builtin_isinf(ninf));
  printf("isinf(nan) = %d\n", __builtin_isinf(nan));
  printf("isinf(1.0) = %d\n", __builtin_isinf(normal));
  printf("isinf(0.0) = %d\n", __builtin_isinf(zero));

  printf("\n=== isnan ===\n");
  printf("isnan(+inf) = %d\n", __builtin_isnan(inf));
  printf("isnan(-inf) = %d\n", __builtin_isnan(ninf));
  printf("isnan(nan) = %d\n", __builtin_isnan(nan));
  printf("isnan(1.0) = %d\n", __builtin_isnan(normal));
  printf("isnan(0.0) = %d\n", __builtin_isnan(zero));

  printf("\n=== combined ===\n");
  printf("isnan(+inf) || isinf(+inf) = %d\n",
         __builtin_isnan(inf) || __builtin_isinf(inf));
  printf("isnan(nan) || isinf(nan) = %d\n",
         __builtin_isnan(nan) || __builtin_isinf(nan));
  printf("isnan(1.0) || isinf(1.0) = %d\n",
         __builtin_isnan(normal) || __builtin_isinf(normal));

  printf("\n=== if ===\n");
  if (__builtin_isinf(inf)) {
    printf("inf is inf\n");
  }
  if (__builtin_isinf(ninf)) {
    printf("ninf is inf\n");
  }
  if (!__builtin_isinf(normal)) {
    printf("normal is not inf\n");
  }

  return 0;
}
