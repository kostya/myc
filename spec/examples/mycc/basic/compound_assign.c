int printf(const char *fmt, ...);

int main() {
  unsigned int x = 16;

  (x >>= 1);
  printf("%u\n", x);

  (x <<= 2);
  printf("%u\n", x);

  (x += 5);
  printf("%u\n", x);

  (x -= 3);
  printf("%u\n", x);

  unsigned int y = (x |= 2);
  printf("%u %u\n", x, y);

  return 0;
}
