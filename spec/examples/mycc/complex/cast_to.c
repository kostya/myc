#include <stdint.h>
#include <stdio.h>

int8_t g_i8 = -1;
uint8_t g_u8 = 1;
int16_t g_i16 = -1;
uint16_t g_u16 = 1;
int32_t g_i32 = -1;
uint32_t g_u32 = 1;
int64_t g_i64 = -1;
uint64_t g_u64 = 1;

int16_t i8_to_i16(void) { return (int16_t)g_i8; }
int32_t i8_to_i32(void) { return (int32_t)g_i8; }
int64_t i8_to_i64(void) { return (int64_t)g_i8; }

uint16_t u8_to_u16(void) { return (uint16_t)g_u8; }
uint32_t u8_to_u32(void) { return (uint32_t)g_u8; }
uint64_t u8_to_u64(void) { return (uint64_t)g_u8; }

int32_t i16_to_i32(void) { return (int32_t)g_i16; }
int64_t i16_to_i64(void) { return (int64_t)g_i16; }

uint32_t u16_to_u32(void) { return (uint32_t)g_u16; }
uint64_t u16_to_u64(void) { return (uint64_t)g_u16; }

int64_t i32_to_i64(void) { return (int64_t)g_i32; }
uint64_t u32_to_u64(void) { return (uint64_t)g_u32; }

int8_t i16_to_i8(void) { return (int8_t)g_i16; }
int8_t i32_to_i8(void) { return (int8_t)g_i32; }
int8_t i64_to_i8(void) { return (int8_t)g_i64; }
int16_t i32_to_i16(void) { return (int16_t)g_i32; }
int16_t i64_to_i16(void) { return (int16_t)g_i64; }
int32_t i64_to_i32(void) { return (int32_t)g_i64; }

uint8_t u16_to_u8(void) { return (uint8_t)g_u16; }
uint8_t u32_to_u8(void) { return (uint8_t)g_u32; }
uint8_t u64_to_u8(void) { return (uint8_t)g_u64; }
uint16_t u32_to_u16(void) { return (uint16_t)g_u32; }
uint16_t u64_to_u16(void) { return (uint16_t)g_u64; }
uint32_t u64_to_u32(void) { return (uint32_t)g_u64; }

int64_t u8_to_i64(void) { return (int64_t)g_u8; }
int64_t u16_to_i64(void) { return (int64_t)g_u16; }
int64_t u32_to_i64(void) { return (int64_t)g_u32; }
uint64_t i8_to_u64(void) { return (uint64_t)g_i8; }
uint64_t i16_to_u64(void) { return (uint64_t)g_i16; }
uint64_t i32_to_u64(void) { return (uint64_t)g_i32; }

int64_t load_i16_as_i64(int16_t *p) { return (int64_t)*p; }
uint64_t load_u16_as_u64(uint16_t *p) { return (uint64_t)*p; }
int64_t load_u16_as_i64(uint16_t *p) { return (int64_t)*p; }
uint64_t load_i16_as_u64(int16_t *p) { return (uint64_t)*p; }
int32_t load_i64_as_i32(int64_t *p) { return (int32_t)*p; }
int64_t load_i32_as_i64(int32_t *p) { return (int64_t)*p; }
int8_t load_i64_as_i8(int64_t *p) { return (int8_t)*p; }

int64_t chain_i8_to_i64(int8_t a) {
  int16_t b = (int16_t)a;
  int32_t c = (int32_t)b;
  int64_t d = (int64_t)c;
  return d;
}

uint64_t chain_u8_to_u64(uint8_t a) {
  uint16_t b = (uint16_t)a;
  uint32_t c = (uint32_t)b;
  uint64_t d = (uint64_t)c;
  return d;
}

int8_t chain_i64_to_i8(int64_t a) {
  int32_t b = (int32_t)a;
  int16_t c = (int16_t)b;
  int8_t d = (int8_t)c;
  return d;
}

int main(void) {

  printf("i8_to_i16  = %d (expect -1)\n", (int)i8_to_i16());
  printf("i8_to_i32  = %d (expect -1)\n", (int)i8_to_i32());
  printf("i8_to_i64  = %lld (expect -1)\n", (long long)i8_to_i64());

  printf("u8_to_u16  = %u (expect 1)\n", (unsigned)u8_to_u16());
  printf("u8_to_u32  = %u (expect 1)\n", (unsigned)u8_to_u32());
  printf("u8_to_u64  = %llu (expect 1)\n", (unsigned long long)u8_to_u64());

  printf("i16_to_i32 = %d (expect -1)\n", (int)i16_to_i32());
  printf("i16_to_i64 = %lld (expect -1)\n", (long long)i16_to_i64());

  printf("u16_to_u32 = %u (expect 1)\n", (unsigned)u16_to_u32());
  printf("u16_to_u64 = %llu (expect 1)\n", (unsigned long long)u16_to_u64());

  printf("i32_to_i64 = %lld (expect -1)\n", (long long)i32_to_i64());
  printf("u32_to_u64 = %llu (expect 1)\n", (unsigned long long)u32_to_u64());

  printf("i16_to_i8  = %d (expect -1)\n", (int)i16_to_i8());
  printf("i32_to_i8  = %d (expect -1)\n", (int)i32_to_i8());
  printf("i64_to_i8  = %d (expect -1)\n", (int)i64_to_i8());
  printf("i32_to_i16 = %d (expect -1)\n", (int)i32_to_i16());
  printf("i64_to_i16 = %d (expect -1)\n", (int)i64_to_i16());
  printf("i64_to_i32 = %d (expect -1)\n", (int)i64_to_i32());

  printf("u16_to_u8  = %u (expect 1)\n", (unsigned)u16_to_u8());
  printf("u32_to_u8  = %u (expect 1)\n", (unsigned)u32_to_u8());
  printf("u64_to_u8  = %u (expect 1)\n", (unsigned)u64_to_u8());
  printf("u32_to_u16 = %u (expect 1)\n", (unsigned)u32_to_u16());
  printf("u64_to_u16 = %u (expect 1)\n", (unsigned)u64_to_u16());
  printf("u64_to_u32 = %u (expect 1)\n", (unsigned)u64_to_u32());

  printf("u8_to_i64  = %lld (expect 1)\n", (long long)u8_to_i64());
  printf("u16_to_i64 = %lld (expect 1)\n", (long long)u16_to_i64());
  printf("u32_to_i64 = %lld (expect 1)\n", (long long)u32_to_i64());
  printf("i8_to_u64  = %llu (expect 18446744073709551615)\n",
         (unsigned long long)i8_to_u64());
  printf("i16_to_u64 = %llu (expect 18446744073709551615)\n",
         (unsigned long long)i16_to_u64());
  printf("i32_to_u64 = %llu (expect 18446744073709551615)\n",
         (unsigned long long)i32_to_u64());

  int16_t s16 = -1;
  uint16_t u16 = 1;
  int64_t s64 = -1;
  int32_t s32 = -1;

  printf("load_i16_as_i64 = %lld (expect -1)\n",
         (long long)load_i16_as_i64(&s16));
  printf("load_u16_as_u64 = %llu (expect 1)\n",
         (unsigned long long)load_u16_as_u64(&u16));
  printf("load_u16_as_i64 = %lld (expect 1)\n",
         (long long)load_u16_as_i64(&u16));
  printf("load_i16_as_u64 = %llu (expect 18446744073709551615)\n",
         (unsigned long long)load_i16_as_u64(&s16));
  printf("load_i64_as_i32 = %d (expect -1)\n", (int)load_i64_as_i32(&s64));
  printf("load_i32_as_i64 = %lld (expect -1)\n",
         (long long)load_i32_as_i64(&s32));
  printf("load_i64_as_i8  = %d (expect -1)\n", (int)load_i64_as_i8(&s64));

  printf("chain_i8_to_i64(-1) = %lld (expect -1)\n",
         (long long)chain_i8_to_i64(-1));
  printf("chain_u8_to_u64(1)  = %llu (expect 1)\n",
         (unsigned long long)chain_u8_to_u64(1));
  printf("chain_i64_to_i8(-1) = %d (expect -1)\n", (int)chain_i64_to_i8(-1));

  int16_t x = -1;
  uint64_t y = (uint64_t)x;
  printf("i16-u64 %llu\n", (unsigned long long)y);

  return 0;
}
