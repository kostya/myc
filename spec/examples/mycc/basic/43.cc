int main() {
  int x = 1;
  printf("x = %d\n", x);

  {
    int x = 2;
    printf("x = %d\n", x);
  }

  printf("x = %d\n", x);

  for (int i = 0; i < 3; i++) {
    int x = 10 + i;
    printf("x = %d\n", x);
  }

  printf("x = %d\n", x);

  if (1) {
    int x = 100;
    printf("x = %d\n", x);
  }

  printf("x = %d\n", x);

  if (0)
    1;
  else {
    double x = 1.5;
    printf("x = %.1f\n", x);
  }

  printf("x = %d\n", x);

  {
    x++;
    printf("x = %d\n", x);
  }

  printf("x = %d\n", x);

  return 0;
}
