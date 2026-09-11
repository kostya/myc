int printf(const char *fmt, ...);

int main() {
  int x = 15;

  if (1) {
    x++;
  }

  printf("%d\n", x);
  return 0;
}
