#include <stdio.h>

__attribute__((noinline)) unsigned char ext_u8(unsigned char a,
                                               unsigned char b) {
  return a + b;
}
__attribute__((noinline)) signed char ext_i8(signed char a, signed char b) {
  return a + b;
}
__attribute__((noinline)) unsigned short ext_u16(unsigned short a,
                                                 unsigned short b) {
  return a + b;
}
__attribute__((noinline)) short ext_i16(short a, short b) { return a + b; }

__attribute__((noinline)) unsigned char ext_va_u8(int n, ...) {
  return (unsigned char)n;
}

unsigned char u8_select(unsigned char cond, unsigned char t, unsigned char f) {
  return cond ? t : f;
}
signed char i8_select(signed char cond, signed char t, signed char f) {
  return cond ? t : f;
}
unsigned short u16_select(unsigned char cond, unsigned short t,
                          unsigned short f) {
  return cond ? t : f;
}
short i16_select(unsigned char cond, short t, short f) { return cond ? t : f; }

unsigned char u8_add(unsigned char a, unsigned char b) { return a + b; }
signed char i8_neg(signed char a) { return -a; }
unsigned short u16_add(unsigned short a, unsigned short b) { return a + b; }
short i16_neg(short a) { return -a; }

unsigned char u8_div(unsigned char a, unsigned char b) { return a / b; }
unsigned short u16_div(unsigned short a, unsigned short b) { return a / b; }
unsigned char u8_rem(unsigned char a, unsigned char b) { return a % b; }

int main() {

  printf("u8 select t     = %d\n", u8_select(1, 200, 100));
  printf("u8 select f     = %d\n", u8_select(0, 200, 100));
  printf("u8 select wrap  = %d\n", u8_select(1, u8_add(200, 100), 0));
  printf("i8 select t     = %d\n", i8_select(1, -128, 0));
  printf("u16 select t    = %d\n", u16_select(1, 65535, 0));
  printf("i16 select t    = %d\n", i16_select(1, -32768, 0));

  printf("ext u8 call     = %d\n", ext_u8(200, 100));
  printf("ext i8 call     = %d\n", ext_i8(127, 1));
  printf("ext u16 call    = %d\n", ext_u16(40000, 40000));
  printf("ext i16 call    = %d\n", ext_i16(32767, 1));

  printf("ext u8 call div = %d\n", u8_div(ext_u8(200, 100), 2));
  printf("ext u16 call div= %d\n", u16_div(ext_u16(40000, 40000), 2));
  printf("ext u8 call rem = %d\n", u8_rem(ext_u8(200, 100), 7));

  printf("ext i8 call neg = %d\n", i8_neg(ext_i8(127, 1)));
  printf("ext i16 call neg= %d\n", i16_neg(ext_i16(32767, 1)));

  printf("va u8           = %d\n", ext_va_u8(200));
  printf("va u8 big       = %d\n", ext_va_u8(300));
  printf("va u8 255       = %d\n", ext_va_u8(255));
  printf("va u8 256       = %d\n", ext_va_u8(256));

  return 0;
}
