int printf(const char *fmt, ...);

struct Bla {
  int x;
  union {
    int a;
    char b;
  } y;
};

void test() {
  static struct Bla bla[2];
  bla[1].x = 10;
  bla[1].y.a = 20;
  printf("%d, %d\n", bla[1].x, bla[1].y.b);
}

int main() {
  test();
  return 0;
}
