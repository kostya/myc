int printf(const char *fmt, ...);

#define test_macro(n, p)                                                       \
  ((n) >= (double)(-9223372036854775807LL) &&                                  \
   (n) < -(double)(-9223372036854775807LL) && (*(p) = (long long)(n), 1))

int main() {
  long long n;

  (*(&n) = 42, 1);
  printf("n = %lld\n", n);

  double d = 42.5;
  if ((d >= 0) && (*(&n) = (long long)d, 1)) {
    printf("n = %lld\n", n);
  }

  if (*(&n) = (2)) {
    printf("n = %lld\n", n);
  }

  int x = 0;
  int *p = &x;
  *p = 10;
  printf("x = %d\n", x);

  int y = 0;
  int *pp = &y;
  **(&pp) = 20;
  printf("y = %d\n", y);

  long long k = 1;
  if (test_macro(d, &k)) {
    printf("k = %d\n", k);
  }

  return 0;
}
