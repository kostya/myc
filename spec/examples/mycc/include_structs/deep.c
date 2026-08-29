int printf(const char *fmt, ...);

struct Level3 {
  char a;
  short b;
  int c;
};

union Level2 {
  struct {
    char x;
    short y;
  } s1;
  struct Level3 s2;
  int z;
};

struct Level1 {
  union {
    struct {
      char p;
      union Level2 u1;
      int q;
    } inner;
    struct {
      short r;
      char s[3];
    } alt;
  } middle;
  long long last;
};

union Final {
  struct Level1 main_struct;
  struct {
    unsigned char first;
    int second;
    struct {
      short a;
      char b[5];
    } third;
  } direct;
  double dbl;
};

int main() {

  union Final data = {0};

  data.main_struct.middle.inner.u1.s2.c = 0x11223344;
  data.main_struct.middle.inner.u1.s2.b = 0x5566;
  data.main_struct.middle.inner.u1.s2.a = 0x77;
  data.main_struct.middle.inner.q = 0xAABBCCDD;
  data.main_struct.middle.inner.p = 0x88;
  data.main_struct.last = 0xFFFFFFFFFFFFFFFF;

  printf("data.direct.first = %d\n", data.direct.first);
  printf("data.direct.second = %d\n", data.direct.second);
  printf("data.direct.third.a = %d\n", data.direct.third.a);
  printf("data.direct.third.b[0] = %d\n", data.direct.third.b[0]);
  printf("data.direct.third.b[1] = %d\n", data.direct.third.b[1]);
  printf("data.main_struct.middle.alt.r = %d\n", data.main_struct.middle.alt.r);
  printf("data.main_struct.middle.alt.s[0] = %d\n",
         data.main_struct.middle.alt.s[0]);
  printf("data.dbl = %f\n", data.dbl);

  return 0;
}
