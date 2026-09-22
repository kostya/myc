int printf(const char *fmt, ...);

int main() {
  switch (3) {
  case 1:
    printf("1\n");
  case 2:
  default:
    printf("default\n");
  }
  return 0;
}
