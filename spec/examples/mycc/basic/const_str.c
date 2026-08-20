int printf(const char *fmt, ...);

static void bla(const char *s) {
  static const int szbla = sizeof("bla") - 1;
  static const char space[] = " \t";
  static const char space2[] = "   ";
  printf("bla `%s` `%s` `%s` %d", s, space, space2, szbla);
}

int main() {
  bla("haha");
  return 0;
}
