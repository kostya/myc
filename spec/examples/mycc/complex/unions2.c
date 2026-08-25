#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct TValue {
  void *value;
  unsigned char tt;
} TValue;

typedef struct UpVal {
  struct {
    void *next;
    unsigned char tt;
    unsigned char marked;
  } CommonHeader;
  union {
    TValue *p;
    long offset;
  } v;
  union {
    struct {
      struct UpVal *next;
      struct UpVal **previous;
    } open;
    TValue value;
  } u;
} UpVal;

int main() {
  UpVal uv1, uv2;

  uv1.u.open.next = (UpVal *)0x1000;
  uv1.v.p = (TValue *)0x2000;

  uv2.u.open.next = (UpVal *)0x3000;
  uv2.v.p = (TValue *)0x4000;

  printf("%zu\n", sizeof(UpVal));
  printf("%zu\n", offsetof(UpVal, v));
  printf("%zu\n", offsetof(UpVal, u));
  printf("%zu\n", offsetof(UpVal, u.open.next));
  printf("%ld\n", (long)uv1.u.open.next);
  printf("%ld\n", (long)uv1.v.p);
  printf("%ld\n", (long)uv2.u.open.next);
  printf("%ld\n", (long)uv2.v.p);

  TValue tv;
  tv.value = (void *)0x5000;
  tv.tt = 42;
  uv1.u.value = tv;

  printf("%ld\n", (long)uv1.u.value.value);
  printf("%d\n", uv1.u.value.tt);
  printf("%ld\n", (long)uv1.u.open.next);

  UpVal *uv = (UpVal *)calloc(3, sizeof(UpVal));
  printf("sizeof(UpVal): %zu\n", sizeof(uv));

  uv[0].u.open.next = &uv[1];
  uv[0].u.open.previous = NULL;
  uv[0].v.p = (TValue *)0x1000;

  uv[1].u.open.next = &uv[2];
  uv[1].u.open.previous = NULL;
  uv[1].v.p = (TValue *)0x2000;

  uv[2].u.open.next = NULL;
  uv[2].u.open.previous = NULL;
  uv[2].v.p = (TValue *)0x3000;

  UpVal *saved_next = uv[0].u.open.next;

  tv.value = (void *)0x9999;
  tv.tt = 42;
  uv[0].u.value = tv;

  printf("u.open.next:       %p\n", (void *)uv[0].u.open.next);

  char *base = (char *)uv;
  char *next_ptr = (char *)&uv[0].u.open.next;
  char *prev_ptr = (char *)&uv[0].u.open.previous;

  long next_offset = next_ptr - base;
  long prev_offset = prev_ptr - base;

  printf("u.open.next offset:     %ld (expected: 24)\n", next_offset);
  printf("u.open.previous offset: %ld (expected: 32)\n", prev_offset);

  free(uv);

  return 0;
}
