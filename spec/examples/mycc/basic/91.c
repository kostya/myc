int printf(const char *fmt, ...);

static void test(double d) {
  long long n;
  if (((d) >= (double)(-9223372036854775807LL) &&
       (d) < -(double)(-9223372036854775807LL) && (*(&n) = (long long)(d), 1)))
    printf("push integer: %lld\n", n);
  else
    printf("push number: %f\n", d);
}

int main() {
  test(42.5);
  test(-1.5);
  return 0;
}
