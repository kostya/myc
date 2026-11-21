int printf(const char *fmt, ...);

int test() {
  while (1) {
    return 10;
  }
}

int test2(int x) {
  if (x == 1) {
    return 11;
  }
}

char test21(int x) {
  if (x == 1) {
    return 12;
  }
}

struct Bla {
  int x;
};

struct Bla test3() {
  while (1) {
    struct Bla bla = {33};
    return bla;
  }
}

struct Bla test4(int x) {
  if (x == 1) {
    struct Bla bla;
    bla.x = 34;
    return bla;
  }
}

int main() {
  printf("%d\n", test());
  printf("%d\n", test2(1));
  printf("%d\n", test21(1));

  printf("%d\n", test3().x);
  printf("%d\n", test4(1).x);

  return 0;
}
