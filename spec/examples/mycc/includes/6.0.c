int printf(const char *fmt, ...);

static int bla() { return 2; }

int external_bla() {
  int (*func_ptr)() = bla;
  return func_ptr();
}
