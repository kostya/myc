int main() {
  int x = 4;
  switch (x) {
  case 4:
    x += 1;
  case 3:
    x += 2;
  case 2:
    x += 3;
  case 1:
    x += 4;
  default:
    break;
  }
  printf("x = %d\n", x);
  return 0;
}
