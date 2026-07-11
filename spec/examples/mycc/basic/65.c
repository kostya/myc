int printf(const char *fmt, ...);

static const char *NAMES[] = {"John", "Jane", "Bob", "Alice"};

int main() {
  printf("%d\n", sizeof(NAMES));
  printf("'%s' + '%s'\n", NAMES[1], NAMES[3]);
  return 0;
}
