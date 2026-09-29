int printf(const char *fmt, ...);
#include <string.h>

static int l_checkmode(const char *mode) {
  int v1 = *mode != '\0' && strchr("rwa", *(mode++)) != NULL;
  int v2 = (*mode != '+' || ((void)(++mode), 1));
  int v3 = (strspn(mode, "b") == strlen(mode));

  printf("%d, %d, %d\n", v1, v2, v3);
  return v1 && v2 && v3;
}

int main() {
  printf("v = %d\n", l_checkmode("r+b"));
  printf("v2 = %d\n", l_checkmode("r+bk"));
  return 0;
}
