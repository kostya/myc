int printf(const char *fmt, ...);

typedef struct {
  char *data;
  int a;
  int b[3];
} A;

static A test() {
  A a = {0};
  printf("%d, %d, %d\n", a.a, a.b[0], a.b[1]);
  a.a = 1;
  a.b[0] = 2;
  *(a.b + 1) = 3;
  printf("%d, %d, %d\n", a.a, a.b[0], a.b[1]);
  return a;
}

int main() {
  test();
  return 0;
}
