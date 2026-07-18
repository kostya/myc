int printf(const char *fmt, ...);
static const char *PATTERN = "\\d+\\.\\d+\\.\\d+\\.35";

int main() {
  printf("pattern %s\n", PATTERN);
  return 0;
}
