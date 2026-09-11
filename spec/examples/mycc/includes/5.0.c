int printf(const char *fmt, ...);

static int bla() { return 2; }

int external_bla() { return bla(); }
