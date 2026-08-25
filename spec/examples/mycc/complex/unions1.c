#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct TValue {
  void *value;
  unsigned char tt;
} TValue;

typedef struct UpVal {
  TValue *v;
  unsigned char tt;
  unsigned char marked;
  union {
    TValue value;
    struct {
      struct UpVal *next;
      struct UpVal **previous;
    } open;
  } u;
} UpVal;

int main() {
  printf("Size of UpVal: %zu bytes\n", sizeof(UpVal));
  printf("v:              %zu\n", offsetof(UpVal, v));
  printf("tt:             %zu\n", offsetof(UpVal, tt));
  printf("marked:         %zu\n", offsetof(UpVal, marked));
  printf("u:              %zu\n", offsetof(UpVal, u));
  printf("u.value:        %zu\n", offsetof(UpVal, u.value));
  printf("u.open.next:    %zu\n", offsetof(UpVal, u.open.next));
  printf("u.open.previous:%zu\n", offsetof(UpVal, u.open.previous));

  printf("sizeof(TValue):      %zu\n", sizeof(TValue));
  printf("alignof(UpVal):      %zu\n", _Alignof(UpVal));
  printf("sizeof(ptr):         %zu\n", sizeof(void *));
  printf("sizeof(unsigned char):%zu\n", sizeof(unsigned char));
  printf("sizeof(union):       %zu\n", sizeof(((UpVal *)0)->u));
  printf("sizeof(open struct): %zu\n", sizeof(((UpVal *)0)->u.open));

  return 0;
}
