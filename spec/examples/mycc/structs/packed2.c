#include "stddef.h"
int printf(const char *fmt, ...);

struct PackedStruct {
  char a;
  int b;
  char c;
} __attribute__((packed));

struct __attribute__((packed)) PackedStruct2 {
  char a;
  int b;
  char c;
};

int main() {
  struct PackedStruct s;
  struct PackedStruct *ptr = &s;
  printf("offset1: %d\n", offsetof(struct PackedStruct, c));
  printf("offset2: %d\n", (char *)&(ptr->c) - (char *)ptr);

  struct PackedStruct2 s2;
  struct PackedStruct2 *ptr2 = &s2;
  printf("offset3: %d\n", offsetof(struct PackedStruct2, c));
  printf("offset4: %d\n", (char *)&(ptr2->c) - (char *)ptr2);

  return 0;
}
