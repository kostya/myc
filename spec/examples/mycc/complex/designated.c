int printf(const char *fmt, ...);

struct FloatZero {
  double d;
  float f;
};

struct PtrCast {
  char *p;
  int x;
};

struct A {
  int a;
};

struct B {
  struct A a;
  int b;
};

struct C {
  struct B b;
  int c;
};

struct D {
  struct C c;
  int d;
};

struct StrEscape {
  char s[8];
};

union U1 {
  int i;
  struct {
    short a;
    short b;
  } s;
};

struct S1 {
  int kind;
  union U1 u;
};

union U2 {
  int i;
  char c;
};

struct S2 {
  int kind;
  union U2 u[3];
};

union U3 {
  int i;
  int arr[4];
};

struct Point {
  int x;
  int y;
};

struct Prop {
  int type;
  union {
    int i;
    double d;
  } u;
};

struct ZeroUnion {
  int kind;
  union {
    int i;
    char c;
  } u;
  int tail;
};

int main() {

  printf("=== 1. FloatZero ===\n");
  struct FloatZero fz = {0};
  printf("d = %f, f = %f\n", fz.d, fz.f);

  printf("\n=== 2. PtrCast ===\n");
  struct PtrCast pc = {0};
  printf("p = %d, x = %d\n", pc.p == (void*)0, pc.x);

  printf("\n=== 3. Deep chain ===\n");
  struct D d = {.d = 1, .c.b.a.a = 42};
  printf("d = %d, a = %d\n", d.d, d.c.b.a.a);

  printf("\n=== 4. StrEscape ===\n");
  struct StrEscape se = {"a\nb"};
  printf("s = %s\n", se.s);

  printf("\n=== 5. S1 ===\n");
  struct S1 s1 = {.kind = 1, .u = {.s = {.a = 10, .b = 20}}};
  printf("kind = %d, a = %d, b = %d\n", s1.kind, s1.u.s.a, s1.u.s.b);

  printf("\n=== 6. S2 ===\n");
  struct S2 s2 = {.kind = 1, .u = {{.i = 10}, {.i = 20}, {.i = 30}}};
  printf("kind = %d, u[0].i = %d, u[1].i = %d, u[2].i = %d\n", s2.kind,
         s2.u[0].i, s2.u[1].i, s2.u[2].i);

  printf("\n=== 7. U3 ===\n");
  union U3 u3 = {.arr = {1, 2, 3, 4}};
  printf("u3.i = %d, u3.arr[0] = %d, u3.arr[3] = %d\n", u3.i, u3.arr[0],
         u3.arr[3]);

  printf("\n=== 8. Point array ===\n");
  struct Point pts[3] = {{.x = 1, .y = 2}, {.x = 3, .y = 4}, {.x = 5, .y = 6}};
  printf("pts[0] = (%d, %d)\n", pts[0].x, pts[0].y);
  printf("pts[1] = (%d, %d)\n", pts[1].x, pts[1].y);
  printf("pts[2] = (%d, %d)\n", pts[2].x, pts[2].y);

  printf("\n=== 9. Prop ===\n");
  struct Prop *p = &(struct Prop){.type = 1, .u = {.i = 42}};
  printf("type = %d, i = %d\n", p->type, p->u.i);

  printf("\n=== 10. ZeroUnion ===\n");
  struct ZeroUnion zu = {0};
  printf("kind = %d, u.i = %d, tail = %d\n", zu.kind, zu.u.i, zu.tail);

  printf("\n=== 11. Double zero ===\n");
  double dz[3] = {0};
  printf("dz[0] = %f, dz[1] = %f, dz[2] = %f\n", dz[0], dz[1], dz[2]);

  printf("\n=== 12. Float zero ===\n");
  float fz2[3] = {0};
  printf("fz2[0] = %f, fz2[1] = %f, fz2[2] = %f\n", fz2[0], fz2[1], fz2[2]);

  printf("\n=== 13. Nested union array ===\n");
  union U4 {
    int i;
    struct {
      int arr[4];
    } s;
  };
  union U4 u4 = {.s.arr = {1, 2, 3, 4}};
  printf("u4.s.arr[0] = %d, u4.s.arr[3] = %d\n", u4.s.arr[0], u4.s.arr[3]);

  printf("\n=== 14. Mixed ===\n");
  struct Point mp = {.x = 10, 20};
  printf("mp = (%d, %d)\n", mp.x, mp.y);

  printf("\n=== 15. Designated array ===\n");
  int arr[5] = {[0] = 1, [2] = 3, [4] = 5};
  printf("arr = [%d, %d, %d, %d, %d]\n", arr[0], arr[1], arr[2], arr[3],
         arr[4]);

  return 0;
}
