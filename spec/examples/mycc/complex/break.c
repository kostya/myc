int printf(const char *fmt, ...);

int test_break_in_if(int x) {
  int result = 0;
  switch (x) {
  case 1:
    if (x > 0) {
      break;
    }
    result = 1;
    break;
  case 2:
    result = 2;
    break;
  default:
    result = 3;
  }
  return result;
}

int test_break_in_for(int x) {
  int result = 0;
  switch (x) {
  case 1:
    for (int i = 0; i < 10; i++) {
      if (i > 5) {
        break;
      }
      result += i;
    }
    result += 100;
    break;
  default:
    result = -1;
  }
  return result;
}

int test_nested_loops(int x) {
  int result = 0;
  switch (x) {
  case 1:
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (i == 1 && j == 1) {
          break;
        }
        result++;
      }
      if (i == 2) {
        break;
      }
    }
    result += 100;
    break;
  default:
    result = -1;
  }
  return result;
}

int test_break_in_while(int x) {
  int result = 0;
  switch (x) {
  case 1:
    int i = 0;
    while (i < 10) {
      i++;
      if (i > 5) {
        break;
      }
    }
    result = i;
    break;
  default:
    result = -1;
  }
  return result;
}

int test_break_in_do_while(int x) {
  int result = 0;
  switch (x) {
  case 1:
    int i = 0;
    do {
      i++;
      if (i > 3) {
        break;
      }
      result += i;
    } while (i < 10);
    result += 100;
    break;
  default:
    result = -1;
  }
  return result;
}

int test_continue_in_switch(int x) {
  int result = 0;
  for (int i = 0; i < 3; i++) {
    switch (x) {
    case 1:
      if (i == 1) {
        continue;
      }
      result += i;
      break;
    default:
      result += 100;
    }
  }
  return result;
}

int main() {

  printf("T1: %d %d %d\n", test_break_in_if(1), test_break_in_if(2),
         test_break_in_if(5));

  printf("T2: %d %d\n", test_break_in_for(1), test_break_in_for(5));

  printf("T3: %d %d\n", test_nested_loops(1), test_nested_loops(5));

  printf("T4: %d %d\n", test_break_in_while(1), test_break_in_while(5));

  printf("T5: %d %d\n", test_break_in_do_while(1), test_break_in_do_while(5));

  printf("T6: %d %d\n", test_continue_in_switch(1), test_continue_in_switch(5));

  return 0;
}
