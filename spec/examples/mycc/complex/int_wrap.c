int printf(const char *fmt, ...);

unsigned char u8_add(unsigned char a, unsigned char b) { return a + b; }
unsigned char u8_sub(unsigned char a, unsigned char b) { return a - b; }
unsigned char u8_mul(unsigned char a, unsigned char b) { return a * b; }
unsigned char u8_div(unsigned char a, unsigned char b) { return a / b; }
unsigned char u8_rem(unsigned char a, unsigned char b) { return a % b; }
unsigned char u8_shl(unsigned char a, unsigned char b) { return a << b; }
unsigned char u8_bnot(unsigned char a) { return ~a; }
unsigned char u8_neg(unsigned char a) { return -a; }

signed char i8_add(signed char a, signed char b) { return a + b; }
signed char i8_sub(signed char a, signed char b) { return a - b; }
signed char i8_mul(signed char a, signed char b) { return a * b; }
signed char i8_bnot(signed char a) { return ~a; }
signed char i8_neg(signed char a) { return -a; }
signed char i8_abs(signed char a) { return a < 0 ? -a : a; }

unsigned short u16_add(unsigned short a, unsigned short b) { return a + b; }
unsigned short u16_sub(unsigned short a, unsigned short b) { return a - b; }
unsigned short u16_mul(unsigned short a, unsigned short b) { return a * b; }
unsigned short u16_div(unsigned short a, unsigned short b) { return a / b; }
unsigned short u16_rem(unsigned short a, unsigned short b) { return a % b; }

short i16_add(short a, short b) { return a + b; }
short i16_sub(short a, short b) { return a - b; }
short i16_neg(short a) { return -a; }
short i16_abs(short a) { return a < 0 ? -a : a; }

unsigned int u32_add(unsigned int a, unsigned int b) { return a + b; }
unsigned int u32_sub(unsigned int a, unsigned int b) { return a - b; }
unsigned int u32_mul(unsigned int a, unsigned int b) { return a * b; }

int i32_add(int a, int b) { return a + b; }
int i32_sub(int a, int b) { return a - b; }
int i32_neg(int a) { return -a; }

unsigned long long u64_add(unsigned long long a, unsigned long long b) {
  return a + b;
}
unsigned long long u64_sub(unsigned long long a, unsigned long long b) {
  return a - b;
}

long long i64_add(long long a, long long b) { return a + b; }
long long i64_sub(long long a, long long b) { return a - b; }
long long i64_neg(long long a) { return -a; }

int main() {

  printf("u8 add          = %d\n", u8_add(200, 100));
  printf("u8 add div      = %d\n", u8_div(u8_add(200, 100), 2));
  printf("u8 add rem      = %d\n", u8_rem(u8_add(200, 100), 7));
  printf("u8 mul          = %d\n", u8_mul(16, 16));
  printf("u8 sub          = %d\n", u8_sub(0, 1));
  printf("u8 shl          = %d\n", u8_shl(255, 1));
  printf("u8 bnot         = %d\n", u8_bnot(0));
  printf("u8 neg          = %d\n", u8_neg(255));

  printf("i8 add          = %d\n", i8_add(127, 1));
  printf("i8 sub          = %d\n", i8_sub(-128, 1));
  printf("i8 mul          = %d\n", i8_mul(100, 2));
  printf("i8 bnot         = %d\n", i8_bnot(0));
  printf("i8 neg          = %d\n", i8_neg(-128));
  printf("i8 abs          = %d\n", i8_abs(-128));

  printf("u16 add         = %d\n", u16_add(65535, 1));
  printf("u16 add2        = %d\n", u16_add(40000, 40000));
  printf("u16 sub         = %d\n", u16_sub(0, 1));
  printf("u16 mul         = %d\n", u16_mul(300, 300));
  printf("u16 add div     = %d\n", u16_div(u16_add(65535, 1), 2));
  printf("u16 add rem     = %d\n", u16_rem(u16_add(65535, 1), 7));

  printf("i16 add         = %d\n", i16_add(32767, 1));
  printf("i16 sub         = %d\n", i16_sub(-32768, 1));
  printf("i16 neg         = %d\n", i16_neg(-32768));
  printf("i16 abs         = %d\n", i16_abs(-32768));

  printf("u32 add         = %u\n", u32_add(4294967295u, 1));
  printf("u32 sub         = %u\n", u32_sub(0, 1));
  printf("u32 mul         = %u\n", u32_mul(65536, 65536));

  printf("i32 add         = %d\n", i32_add(2147483647, 1));
  printf("i32 sub         = %d\n", i32_sub(-2147483648, 1));
  printf("i32 neg         = %d\n", i32_neg(-2147483648));

  printf("u64 add         = %llu\n", u64_add(18446744073709551615ull, 1));
  printf("u64 sub         = %llu\n", u64_sub(0, 1));

  printf("i64 add         = %lld\n", i64_add(9223372036854775807ll, 1));
  printf("i64 sub         = %lld\n", i64_sub(-9223372036854775808ll, 1));
  printf("i64 neg         = %lld\n", i64_neg(-9223372036854775808ll));

  return 0;
}
