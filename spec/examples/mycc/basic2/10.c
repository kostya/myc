int printf(const char *fmt, ...);

int main() {
  unsigned int ran = 100;
  unsigned int lim = 15;
  unsigned int n = 5;

  while ((ran &= lim) > n) {
    ran = 100;
  }

  printf("final: ran=%u, lim=%u, n=%u\n", ran, lim, n);

  return 0;
}
