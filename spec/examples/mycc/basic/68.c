int printf(const char *fmt, ...);

int test_bnot_types() {
  int a = 0;
  unsigned int b = 0;
  long c = 0;
  unsigned long d = 0;

  int ra = ~a;
  unsigned int rb = ~b;
  long rc = ~c;
  unsigned long rd = ~d;

  printf("  ~int: %d (expect -1)\n", ra);
  printf("  ~uint: %u (expect 4294967295)\n", rb);
  printf("  ~long: %ld (expect -1)\n", rc);
  printf("  ~ulong: %lu (expect 18446744073709551615)\n", rd);

  return 0;
}

int test_unary_types() {

  int a = 0;
  long c = 0;

  int ra = ~a;
  long rc = ~c;

  printf("  ~int: %d (expect -1)\n", ra);
  printf("  ~long: %ld (expect -1)\n", rc);

  int x = 42;
  long y = 0;

  int lx = !x;
  int ly = !y;

  printf("  !42: %d (expect 0)\n", lx);
  printf("  !0L: %d (expect 1)\n", ly);

  int neg_i = -42;
  long neg_l = -42L;

  printf("  -42: %d (expect -42)\n", neg_i);
  printf("  -42L: %ld (expect -42)\n", neg_l);

  return 0;
}

int main() {
  test_bnot_types();
  test_unary_types();
  return 0;
}
