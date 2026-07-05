void test_union_in_func(void) {
  union {
    int x;
    float y;
  } u;

  u.x = 42;
  printf("u.x = %d\n", u.x);

  u.y = 3.14f;
  printf("u.y = %.2f\n", u.y);
}

void test_struct_in_func(void) {
  struct {
    int a;
    char b;
  } s;

  s.a = 10;
  s.b = 'X';
  printf("s.a = %d, s.b = %c\n", s.a, s.b);
}

void test_typedef_in_func(void) {
  typedef struct {
    int x;
    int y;
  } Point;

  Point p = {10, 20};
  printf("Point: %d, %d\n", p.x, p.y);
}

void test_bit_cast(void) {
  union {
    int x;
    float y;
  } u;

  u.x = 42;
  printf("u.x = %d\n", u.x);
  printf("u.y = %.7f\n", u.y);

  u.y = 3.14f;
  printf("u.x = %d\n", u.x);
  printf("u.y = %.7f\n", u.y);
}

void test_union_typedef_in_func(void) {
  typedef union {
    int i;
    float f;
  } IntOrFloat;

  IntOrFloat v;
  v.i = 42;
  printf("v.i = %d\n", v.i);
  v.f = 3.14f;
  printf("v.f = %f\n", v.f);
}

void test_typedef_in_func2(void) {
  typedef int bla;
  bla v = 42;
  printf("bla = %d\n", v);
}

int main() {
  test_union_in_func();
  test_struct_in_func();
  test_typedef_in_func();
  test_union_typedef_in_func();
  test_bit_cast();
  test_typedef_in_func2();
  return 0;
}
