int main() {
  int x = 1;

  {

    printf("inner1: %d\n", x);
    x = 2;
    printf("inner1 after set: %d\n", x);
  }

  printf("outer after inner1: %d\n", x);

  {
    int x = 10;
    printf("inner2: %d\n", x);
  }

  printf("outer after inner2: %d\n", x);

  {
    int y = 100;
    {

      printf("deep: x=%d y=%d\n", x, y);
    }
  }

  return 0;
}
