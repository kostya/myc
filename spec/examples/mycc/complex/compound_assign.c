int printf(const char *fmt, ...);

int main() {
  int x, y, z, w;
  int result;

  x = 100;
  y = 15;
  if ((x &= y) > 5) {
    printf("1. if: x=%d\n", x);
  } else {
    printf("1. if: x=%d (else)\n", x);
  }

  x = 100;
  y = 15;
  z = 5;
  while ((x &= y) > z) {
    printf("2. while: x=%d\n", x);
    x = 100;
    z = 100;
  }
  printf("2. final: x=%d\n", x);

  x = 100;
  y = 15;
  for (int i = 0; (x &= y) > 5; i++) {
    printf("3. for: x=%d\n", x);
    x = 100;
    if (i > 0)
      break;
  }
  printf("3. final: x=%d\n", x);

  x = 100;
  y = 15;
  int count = 0;
  do {
    printf("4. do-while: x=%d\n", x);
    x = 100;
    count++;
  } while ((x &= y) > 5 && count < 2);
  printf("4. final: x=%d\n", x);

  x = 100;
  y = 15;
  switch ((x &= y)) {
  case 0:
    printf("5. switch: x=0\n");
    break;
  case 4:
    printf("5. switch: x=4\n");
    break;
  default:
    printf("5. switch: x=%d\n", x);
    break;
  }

  x = 100;
  y = 15;
  result = ((x &= y) > 5) ? x : -1;
  printf("6. ternary: result=%d, x=%d\n", result, x);

  x = 100;
  y = 15;

  x = 100;
  y = 15;
  if ((x &= y) > 5 && (x |= 1) > 0) {
    printf("8. &&: x=%d\n", x);
  }
  printf("8. final: x=%d\n", x);

  x = 100;
  y = 15;
  if ((x &= y) > 100 || (x |= 1) > 0) {
    printf("9. ||: x=%d\n", x);
  }
  printf("9. final: x=%d\n", x);

  x = 100;
  y = 15;
  printf("10. arg: x=%d\n", (x &= y));
  printf("10. final: x=%d\n", x);

  int arr[20] = {0};
  for (int i = 0; i < 20; i++)
    arr[i] = i;
  x = 100;
  y = 15;
  printf("11. index: arr[x &= y]=%d, x=%d\n", arr[x &= y], x);

  x = 100;
  y = 15;

  x = 0xF0;
  y = 0x0F;
  z = 0xFF;
  result = ((x |= y) & z) >> 1;
  printf("13. nested: x=%d, y=%d, z=%d, result=%d\n", x, y, z, result);

  x = 100;
  y = 15;
  z = 3;
  w = 2;
  result = ((x &= y) > z) ? ((x |= w) + 1) : ((x ^= z) - 1);
  printf("14. complex: x=%d, result=%d\n", x, result);

  x = 100;
  y = 15;
  if ((x &= y) > 10) {
    printf("15. if: x=%d\n", x);
  } else if ((x |= 1) > 0) {
    printf("15. else if: x=%d\n", x);
  } else {
    printf("15. else: x=%d\n", x);
  }

  return 0;
}
