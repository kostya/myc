int printf(const char *fmt, ...);

int main() {
  int x;
  int y;
  int z;
  (x = 1, y = 2, z = 3);
  printf("%d %d %d\n", x, y, z);
  return 0;
}
