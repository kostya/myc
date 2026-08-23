int printf(const char *fmt, ...);

int main() {
  int *b;
  int **a = &b;
  int c = 10;
  *a = b = &c;
  printf("a = %d, b = %d\n", **a, *b);
  return 0;
}
