int printf(const char *fmt, ...);

void bla() { printf("hello\n"); }

void bla();

int main() {
  bla();
  return 0;
}
