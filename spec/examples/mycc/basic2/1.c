int printf(const char *fmt, ...);

static char Output0[] = "bla1";
static char Output[] = {"bla2"};
static int bla = {1};
static const char *arr[3] = {"aaaa", "bbbb"};

int main() {
  printf("%s\n", Output0);
  printf("%s\n", Output);
  printf("%d\n", bla);
  printf("%s\n", arr[0]);
  printf("%s\n", arr[1]);
  printf("%d\n", arr[2] == 0);
  return 0;
}
