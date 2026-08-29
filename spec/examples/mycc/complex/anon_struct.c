int printf(const char *fmt, ...);

struct Outer {
  int before;
  struct {
    int x;
    int y;
  };
  int after;
};

int test_anon_struct_inside() {
  struct Outer o;
  o.before = 10;
  o.x = 20;
  o.y = 30;
  o.after = 40;
  printf("  anon struct inside: before=%d x=%d y=%d after=%d\n", o.before, o.x,
         o.y, o.after);
  return 0;
}

struct Outer1 {
  int before;
  struct Inner1 {
    int x;
    int y;
  } bla;
  int after;
};

int test_anon_struct_inside1() {
  struct Outer1 o;
  o.before = 10;
  o.bla.x = 20;
  o.bla.y = 30;
  o.after = 40;
  printf("  anon struct inside1: before=%d x=%d y=%d after=%d\n", o.before,
         o.bla.x, o.bla.y, o.after);
  return 0;
}

struct Outer2 {
  int before;
  struct Inner2 {
    int x;
    int y;
    struct Inner3 {
      int z;
      struct Inner4 {
        int q;
      } inner4;
    } inner3;
  } bla;
  int after;
};

int test_anon_struct_inside2() {
  struct Outer2 o;
  o.before = 10;
  o.bla.x = 20;
  o.bla.y = 30;
  o.bla.inner3.z = 31;
  o.bla.inner3.inner4.q = 32;
  o.after = 40;
  printf("  anon struct inside2: before=%d x=%d y=%d after=%d %d %d\n",
         o.before, o.bla.x, o.bla.y, o.after, o.bla.inner3.z,
         o.bla.inner3.inner4.q);
  return 0;
}

union AnonInUnion {
  int type;
  struct {
    int width;
    int height;
  };
};

int test_anon_in_union() {
  union AnonInUnion u;
  u.type = 0;
  u.width = 100;
  u.height = 200;
  printf("  anon in union: type=%d width=%d height=%d\n", u.type, u.width,
         u.height);
  return 0;
}

struct WithAnonUnion {
  char kind;
  union {
    int int_val;
    float float_val;
    char str[8];
  };
};

int test_anon_union_inside() {
  struct WithAnonUnion w;
  w.kind = 'i';
  w.int_val = 42;
  printf("  anon union inside: kind=%c int_val=%d\n", w.kind, w.int_val);
  w.kind = 'f';
  w.float_val = 3.14f;
  printf("  anon union inside: kind=%c float_val=%f\n", w.kind, w.float_val);
  return 0;
}

struct DeepNest {
  int level;
  struct {
    int a;
    union {
      int b;
      struct {
        short c;
        short d;
      };
    };
    int e;
  };
  int after;
};

int test_deep_nest() {
  struct DeepNest d;
  d.level = 1;
  d.a = 10;
  d.b = 20;
  d.c = 30;
  d.d = 40;
  d.e = 50;
  d.after = 60;
  printf("  deep nest: level=%d a=%d b=%d c=%d d=%d e=%d after=%d\n", d.level,
         d.a, d.b, d.c, d.d, d.e, d.after);
  return 0;
}

int main() {
  printf("=== Anon Struct/Union Tests ===\n");
  test_anon_struct_inside();
  test_anon_struct_inside1();
  test_anon_struct_inside2();
  test_anon_in_union();
  test_anon_union_inside();
  test_deep_nest();
  printf("=== DONE ===\n");
  return 0;
}
