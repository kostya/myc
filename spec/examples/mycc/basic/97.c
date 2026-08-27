int printf(const char *fmt, ...);

void test(char **argv) { printf("%s\n", argv[-1]); }

int main() {
  char *argv[] = {"abc", "edf"};
  char **p = &argv[1];
  test(p);
  return 0;
}
