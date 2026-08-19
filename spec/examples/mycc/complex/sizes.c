#include <stdio.h>

struct Simple {
  char c;
  int i;
};
struct WithPadding {
  char c1;
  double d;
  char c2;
};
union Data {
  int i;
  float f;
  char str[20];
};

enum Color { RED, GREEN, BLUE };
enum LargeEnum { A = 1, B = 1000, C = 1000000 };

void test1() {
  printf("sizeof(char)               = %zu\n", sizeof(char));
  printf("sizeof(unsigned char)      = %zu\n", sizeof(unsigned char));
  printf("sizeof(signed char)        = %zu\n", sizeof(signed char));

  printf("sizeof(short)              = %zu\n", sizeof(short));
  printf("sizeof(unsigned short)     = %zu\n", sizeof(unsigned short));

  printf("sizeof(int)                = %zu\n", sizeof(int));
  printf("sizeof(unsigned int)       = %zu\n", sizeof(unsigned int));
  printf("sizeof(unsigned)           = %zu\n", sizeof(unsigned));
  printf("sizeof(signed)             = %zu\n", sizeof(signed));

  printf("sizeof(long)               = %zu\n", sizeof(long));
  printf("sizeof(unsigned long)      = %zu\n", sizeof(unsigned long));

  printf("sizeof(long long)          = %zu\n", sizeof(long long));
  printf("sizeof(unsigned long long) = %zu\n", sizeof(unsigned long long));

  printf("sizeof(float)              = %zu\n", sizeof(float));
  printf("sizeof(double)             = %zu\n", sizeof(double));
  printf("sizeof(long double)        = %zu\n", sizeof(long double));

  printf("sizeof(void*)              = %zu\n", sizeof(void *));
  printf("sizeof(char*)              = %zu\n", sizeof(char *));
  printf("sizeof(int*)               = %zu\n", sizeof(int *));
  printf("sizeof(double*)            = %zu\n", sizeof(double *));
  printf("\n");
}

void test2() {
  char c = 'A';
  char arr[10];

  printf("sizeof(char)     = %zu\n", sizeof(char));
  printf("sizeof('A')      = %zu\n", sizeof('A'));
  printf("sizeof(c)        = %zu\n", sizeof(c));
  printf("sizeof(arr)      = %zu\n", sizeof(arr));
  printf("sizeof(arr)/sizeof(arr[0]) = %zu\n", sizeof(arr) / sizeof(arr[0]));

  char *ptr = &c;
  printf("sizeof(ptr)      = %zu\n", sizeof(ptr));
  printf("sizeof(*ptr)     = %zu\n", sizeof(*ptr));
  printf("\n");
}

void test3() {
  char arr[10];
  int arr_int[5];
  double arr_double[3];
  printf("sizeof(char[10])           = %zu\n", sizeof(arr));
  printf("sizeof(int[5])             = %zu\n", sizeof(arr_int));
  printf("sizeof(double[3])          = %zu\n", sizeof(arr_double));

  printf("sizeof(\"Hello\")           = %zu\n", sizeof("Hello"));
  printf("sizeof(\"Hello World\")     = %zu\n", sizeof("Hello World"));

  printf("sizeof(struct Simple)      = %zu\n", sizeof(struct Simple));
  printf("sizeof(struct WithPadding) = %zu\n", sizeof(struct WithPadding));
  printf("sizeof(union Data)         = %zu\n", sizeof(union Data));

  printf("sizeof(enum Color)         = %zu\n", sizeof(enum Color));
  printf("sizeof(enum LargeEnum)     = %zu\n", sizeof(enum LargeEnum));
  printf("\n");
}

void test4() {
#ifdef __STDC_VERSION__
#if __STDC_VERSION__ >= 199901L
#include <stdbool.h>
  printf("sizeof(bool)               = %zu\n", sizeof(bool));
  printf("sizeof(_Bool)              = %zu\n", sizeof(_Bool));
#endif
#endif
  printf("\n");
}

int main() {
  test1();
  test2();
  test3();
  test4();

  return 0;
}
