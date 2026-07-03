#define NULL ((void*)0)

int bla(int x) {
  return x + 1;
}

int main() {
  int(*tmp)(int) = NULL;

  if (tmp) {
    printf("no tmp\n");
  }

  tmp = &bla;

  if (tmp) {
    printf("tmp = %d\n", tmp(25));
  }

  void *ptr = &bla;
  tmp = ptr;

  if (tmp) {
    printf("tmp2 = %d\n", tmp(26));
  }

  return 0;
}
