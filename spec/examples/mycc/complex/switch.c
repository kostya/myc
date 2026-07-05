int main() {
  int x;

  x = 1;
  switch (x) {
  case 1:
    x += 10;
  case 2:
    x += 20;
  case 3:
    x += 30;
  default:
    break;
  }
  printf("fall-through: x = %d\n", x);

  x = 2;
  switch (x) {
  case 1:
    x += 10;
    break;
  case 2:
    x += 20;
    break;
  case 3:
    x += 30;
    break;
  default:
    break;
  }
  printf("with break: x = %d\n", x);

  x = 99;
  switch (x) {
  default:
    x = 0;
  case 1:
    x += 10;
    break;
  case 2:
    x += 20;
    break;
  }
  printf("default first: x = %d\n", x);

  x = 3;
  switch (x) {
  case 1:
  case 2:
  case 3:
    x = 100;
    break;
  default:
    x = 0;
    break;
  }
  printf("multiple cases: x = %d\n", x);

  x = 1;
  switch (x) {
  case 1:
  case 2:
    x = 200;
    break;
  default:
    x = 0;
    break;
  }
  printf("empty case: x = %d\n", x);

  x = 5;
  switch (x) {
  case 1:
    x = 10;
    break;
  case 2:
    x = 20;
    break;
  }
  printf("no default: x = %d\n", x);

  x = 1;
  int y = 2;
  switch (x) {
  case 1:
    switch (y) {
    case 2:
      y = 20;
      break;
    default:
      y = 0;
      break;
    }
    x = 10;
    break;
  default:
    x = 0;
    break;
  }
  printf("nested switch: x=%d y=%d\n", x, y);

  return 0;
}
