int printf(const char *fmt, ...);

int main() {
  double d = 1.0 / 0.0;

  if (__builtin_isnan(d) || __builtin_isinf(d)) {
    printf("null\n");
  } else {
    printf("number\n");
  }

  return 0;
}
