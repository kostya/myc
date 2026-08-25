#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#define HEADER                                                                 \
  void *p;                                                                     \
  unsigned char a;

struct S {
  HEADER;
  union {
    void *x;
    long y;
  } v;
};

int main() {
  struct S *s = (struct S *)calloc(1, sizeof(struct S));

  printf("%zu\n", sizeof(struct S));
  printf("%zu\n", offsetof(struct S, v));
  printf("%td\n", (char *)&s->v - (char *)s);

  free(s);
  return 0;
}
