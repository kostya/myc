int printf(const char *fmt, ...);

struct Point {
  int x;
  int y;
};

int main() {
  struct Point pts[3] = {[1] = {.x = 7, .y = 8}, [2] = {.y = 11}};

  printf("pts[0] = (%d, %d)\n", pts[0].x, pts[0].y);
  printf("pts[1] = (%d, %d)\n", pts[1].x, pts[1].y);
  printf("pts[2] = (%d, %d)\n", pts[2].x, pts[2].y);

  return 0;
}
