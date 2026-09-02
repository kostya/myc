int printf(const char *fmt, ...);

void test1() {
  int x[1][2] = {{3, 4}};
  printf("%d %d\n", x[0][0], x[0][1]);
}

void test2(int a, int b) {
  int x[a][b];
  x[0][0] = 5;
  x[0][1] = 6;
  printf("%d %d\n", x[0][0], x[0][1]);
}

int main() {
  test1();
  test2(1, 2);
  return 0;
}
