int printf(const char *fmt, ...);

static const char *IPS[5];

int main() {
  IPS[0] = "hello";
  printf("%s\n", IPS[0]);
  return 0;
}
