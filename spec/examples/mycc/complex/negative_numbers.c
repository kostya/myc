int printf(const char *fmt, ...);

int main() {

  double neg_float = -2.23307578892655734e-01;
  double small_float = 1.5e-300;
  double big_float = 1.5e+300;
  double neg_scientific = -1.5e-10;
  double zero = 0.0;
  double neg_zero = -0.0;
  float float_small = -3.14f;

  printf("%.7f\n", neg_float);
  printf("%g\n", small_float);
  printf("%g\n", big_float);
  printf("%.10f\n", neg_scientific);
  printf("%.1f\n", zero);
  printf("%.1f\n", neg_zero);
  printf("%.2f\n", float_small);

  int neg_int = -42;
  int min_int = -2147483648;
  int max_int = 2147483647;
  unsigned int max_uint = 4294967295U;
  long long big_int = 9223372036854775807LL;
  long long neg_big_int = -9223372036854775807LL;
  unsigned long long max_ull = 18446744073709551615ULL;

  printf("%d\n", neg_int);
  printf("%d\n", min_int);
  printf("%d\n", max_int);
  printf("%u\n", max_uint);
  printf("%lld\n", big_int);
  printf("%lld\n", neg_big_int);
  printf("%llu\n", max_ull);

  int hex_val = 0xFF;
  int octal_val = 0777;
  int binary_val = 0b1010;

  printf("0x%X %o %d\n", hex_val, octal_val, binary_val);

  char ch = 'A';
  signed char neg_ch = -128;
  unsigned char uchar = 255;

  printf("%c %d %u\n", ch, neg_ch, uchar);

  return 0;
}
