int main() {
  int a = 1;
  printf("a0 = %d\n", a);

  {
    int a = 2;
    printf("a1 = %d\n", a);
    {
      int a = 3;
      printf("a2 = %d\n", a);
    }
    printf("a1 = %d\n", a);
  }
  printf("a0 = %d\n", a);

  if (a) {
    int a = 10;
    printf("if a = %d\n", a);
    if (a > 5) {
      int a = 20;
      printf("if if a = %d\n", a);
    }
    printf("if a = %d\n", a);
  }

  for (int i = 0; i < 2; i++) {
    int a = i + 100;
    printf("for a = %d\n", a);
  }

  while (a < 3) {
    int a = 200;
    printf("while a = %d\n", a);
    break;
  }

  printf("a0 = %d\n", a);

  return 0;
}
