void foo(char *s) { printf("foo: %s\n", s); }

char *bar(void) {
  char *arr = "hello";
  return arr;
}

int main() {

  char buff[4] = "Hi\0";
  foo(buff);

  char *p = buff;
  printf("p: %s\n", p);

  printf("buff+1: %s\n", buff + 1);

  char *s = bar();
  printf("bar: %s\n", s);

  printf("buff: %s\n", buff);

  if (buff) {
    printf("buff not null\n");
  }

  if (buff == p) {
    printf("buff == p\n");
  }

  return 0;
}
