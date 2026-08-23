int printf(const char *fmt, ...);

void do_something() { printf("something\n"); }
void do_other() { printf("other\n"); }

int main() {
  int x = 5;

  (x > 3) ? do_something() : do_other();

  int y = (x > 3) ? 10 : 20;
  printf("%d\n", y);

  (x > 10) ? ((x > 20) ? do_something() : do_other()) : do_something();

  return 0;
}
