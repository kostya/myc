int printf(const char *fmt, ...);

int main() {
  printf("i64 max         = %lli\n", 9223372036854775807ll);
  printf("u64 max         = %llu\n", 18446744073709551615ull);
  return 0;
}
