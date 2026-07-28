int printf(const char *fmt, ...);

struct PackedStruct {
  char a;
  int b;
  char c;
} __attribute__((packed));

int test_packed_struct() {
  struct PackedStruct s;
  s.a = 1;
  s.b = 2;
  s.c = 3;
  printf("  packed: a=%d b=%d c=%d\n", s.a, s.b, s.c);
  printf("  packed sizeof: %d (expect < 12)\n", sizeof(s));
  return 0;
}

union AnonUnion {
  struct {
    int x;
    int y;
  };
  long long raw;
};

int test_anon_union() {
  union AnonUnion u;
  u.x = 10;
  u.y = 20;
  printf("  anon union: x=%d y=%d\n", u.x, u.y);
  u.raw = 0x000000050000000A;
  printf("  anon union raw: x=%d y=%d\n", u.x, u.y);
  return 0;
}

struct PackedAnon {
  char header;
  union {
    struct {
      short a;
      short b;
    } __attribute__((packed));
    int raw;
  };
  char footer;
} __attribute__((packed));

int test_packed_anon() {
  struct PackedAnon p;
  p.header = 0x11;
  p.a = 0x2222;
  p.b = 0x3333;
  p.footer = 0x44;
  printf("  packed anon: header=%x a=%x b=%x footer=%x\n", p.header, p.a, p.b,
         p.footer);
  printf("  packed anon sizeof: %d\n", sizeof(p));
  return 0;
}

int main() {
  printf("=== Packed/Anon Tests ===\n");
  test_packed_struct();
  test_anon_union();
  test_packed_anon();
  printf("=== DONE ===\n");
  return 0;
}
