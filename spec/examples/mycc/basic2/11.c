int printf(const char *fmt, ...);

void test(unsigned int x) {
  while ((x >>= 7) != 0) {
    printf("x=%u\n", x);
  }
  printf("final: x=%u\n", x);
}

int main() {
  test(1000);
  return 0;
}
