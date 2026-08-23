int printf(const char *fmt, ...);

typedef struct TValue {
  int type;
  union {
    int i;
    double d;
    void *p;
  } value;
} TValue;

typedef struct Udata {
  int nuvalue;
  TValue uv[1];
} Udata;

void *get_udata_mem(Udata *u) { return (void *)(u->uv); }

int main() {
  Udata u;
  TValue tv;
  u.nuvalue = 2;

  printf("%zu\n", sizeof(get_udata_mem(&u)));
  printf("%zu\n", sizeof(tv.value));
  printf("%zu\n", sizeof(TValue));
  printf("%zu\n", sizeof(*u.uv));
  printf("%zu\n", sizeof(u.uv[0]));

  return 0;
}
