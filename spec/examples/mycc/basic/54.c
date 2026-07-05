#define MY_MACRO (42)
#define MY_MACRO2 (0xABCDu)
#define MY_MACRO3 (3.14)
#define MY_STR "hello"

int main() {
  int a = MY_MACRO;
  unsigned b = MY_MACRO2;
  float c = MY_MACRO3;

  printf("a = %d, b = %u, c = %.2f\n", a, b, c);
  printf("%s\n", MY_STR);
  return 0;
}
