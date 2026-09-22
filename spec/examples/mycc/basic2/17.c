int printf(const char *fmt, ...);

struct Bla {
  int x;
  int y;
};

void test() {
  static struct Bla bla[2];
  bla[1].x = 10;
  bla[1].y = 20;
  printf("%d, %d\n", bla[1].x, bla[1].y);
}

int main() {
  test();
  return 0;
}
