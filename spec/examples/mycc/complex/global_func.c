int printf(const char *fmt, ...);

typedef struct State State;

typedef int (*CFunction)(State *L);

typedef struct Reg {
  const char *name;
  CFunction func;
} Reg;

static int tcreate(State *L);

static const Reg tab_funcs[] = {{"create", tcreate},
                                {((void *)0), ((void *)0)}};

static int tcreate(State *L) { return 10; }

int main() {
  printf("val = %d\n", tab_funcs[0].func((State *)0));
  return 0;
}
