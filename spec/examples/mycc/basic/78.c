#include <stdio.h>

typedef union {
  int i;
  char d;
} MyUnion;

typedef struct {
  int kind;
  MyUnion u;
} MyStruct;

static MyStruct bla = {2, {3}};
static MyStruct zero = {0};
static MyStruct arr[3] = {{1, {10}}, {2, {20}}, {3, {30}}};

int main() {
  MyStruct a = {1, {0}};
  printf("a.u.i = %d\n", a.u.i);
  printf("a.u.d = %d\n\n", a.u.d);

  MyStruct b = {1, {42}};
  printf("b.u.i = %d\n", b.u.i);
  printf("b.u.d = %d\n\n", b.u.d);

  printf("bla.u.i = %d\n", bla.u.i);
  printf("bla.u.d = %d\n\n", bla.u.d);

  printf("zero.u.i = %d\n", zero.u.i);
  printf("zero.u.d = %d\n\n", zero.u.d);

  printf("arr[1].u.i = %d\n", arr[1].u.i);
  printf("arr[1].u.d = %d\n\n", arr[1].u.d);

  return 0;
}
