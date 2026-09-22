int printf(const char *fmt, ...);

struct Point {
  int x[3];
  int y[4];
};

int main() {
  struct Point p = {0};
  p.x[0] = 1;
  printf("%d, %d\n", p.x[0], p.x[1]);
  return 0;
}
