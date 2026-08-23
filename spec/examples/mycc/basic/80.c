int printf(const char *fmt, ...);
int bla() { return 1; }

int main() {
  int i = 0;
  while ((void)bla(), i < 3) {
    i++;
  }

  printf("i = %d\n", i);
  return 0;
}
