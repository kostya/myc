int printf(const char *fmt, ...);

static char Output[] = "bla2";
static const char *output = Output;

int main() {
  printf("%s\n", output);
  return 0;
}
