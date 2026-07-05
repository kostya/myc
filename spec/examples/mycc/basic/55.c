#define NESTED_MACRO 0xABCDEFu

#define OUTER_MACRO                                                            \
  do {                                                                         \
    unsigned x = NESTED_MACRO;                                                 \
    printf("%u\n", x);                                                         \
  } while (0)

int main() {
  OUTER_MACRO;
  return 0;
}
