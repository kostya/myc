int printf(const char *fmt, ...);

typedef union {
  int i;
  struct {
    short a;
    short b;
  } s;
} U;

typedef struct {
  int kind;
  U u;
} S;

int main() {

  S *p = &(S){.kind = 1, .u = {.s = {.a = 10, .b = 20}}};

  printf("kind = %d, a = %d, b = %d\n", p->kind, p->u.s.a, p->u.s.b);
  return 0;
}
