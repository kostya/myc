int printf(const char *fmt, ...);

#define MAX(a, b)                                                              \
  ({                                                                           \
    int _a = (a);                                                              \
    int _b = (b);                                                              \
    _a > _b ? _a : _b;                                                         \
  })

#define MIN(a, b)                                                              \
  ({                                                                           \
    int _a = (a);                                                              \
    int _b = (b);                                                              \
    _a < _b ? _a : _b;                                                         \
  })

#define SWAP(a, b)                                                             \
  ({                                                                           \
    int _tmp = (a);                                                            \
    (a) = (b);                                                                 \
    (b) = _tmp;                                                                \
  })

#define ABS(x)                                                                 \
  ({                                                                           \
    int _x = (x);                                                              \
    _x < 0 ? -_x : _x;                                                         \
  })

int main() {

  int a, b;
  int c = ({
    a = 1;
    b = 2;
    a + b;
  });
  printf("1. base: a=%d b=%d c=%d\n", a, b, c);

  int x = 10;
  int y = ({
    int x = 5;
    x * 2;
  });
  printf("2. scope: x=%d y=%d\n", x, y);

  int n = 5;
  int result = ({
    int r;
    if (n > 0) {
      r = 100;
    } else {
      r = -100;
    }
    r;
  });
  printf("3. if: result=%d\n", result);

  int sum = ({
    int s = 0;
    for (int i = 1; i <= 5; i++) {
      s += i;
    }
    s;
  });
  printf("4. for: sum=%d\n", sum);

  int p = 1, q = 2;
  int r = 10 + ({
                 p = 5;
                 q = 6;
                 p + q;
               }) * 2;
  printf("5. expr: p=%d q=%d r=%d\n", p, q, r);

  int counter = 0;
  int cnt = ({
    counter++;
    counter++;
    counter++;
    counter;
  });
  printf("6. side: counter=%d cnt=%d\n", counter, cnt);

  int nested = ({
    int inner = ({
      int z = 5;
      z * 2;
    });
    inner + 1;
  });
  printf("7. nested: nested=%d\n", nested);

  int arg = 10;
  printf("8. arg: result=%d\n", ({
           arg *= 2;
           arg + 5;
         }));
  printf("8. arg: arg=%d\n", arg);

  int cond = 5;
  if (({
        int t = cond * 2;
        t > 5;
      })) {
    printf("9. cond: cond > 2.5\n");
  } else {
    printf("9. cond: cond <= 2.5\n");
  }

  int collatz = ({
    int num = 100;
    int steps = 0;
    while (num > 1) {
      if (num % 2 == 0)
        num /= 2;
      else
        num = 3 * num + 1;
      steps++;
    }
    steps;
  });
  printf("10. while: collatz=%d\n", collatz);

  int sw = 2;
  int sw_result = ({
    int res = 0;
    switch (sw) {
    case 1:
      res = 10;
      break;
    case 2:
      res = 20;
      break;
    case 3:
      res = 30;
      break;
    default:
      res = -1;
    }
    res;
  });
  printf("11. switch: sw_result=%d\n", sw_result);

  int v = 10;
  ({
    if (v > 5) {
      printf("12. void: v > 5\n");
    } else {
      printf("12. void: v <= 5\n");
    }
  });

  int m1 = 10, m2 = 20;
  printf("13. MAX: %d\n", MAX(m1, m2));
  printf("13. MIN: %d\n", MIN(m1, m2));
  printf("13. ABS: %d\n", ABS(-42));

  SWAP(m1, m2);
  printf("13. SWAP: m1=%d m2=%d\n", m1, m2);

  int multi = ({
    int t1 = 1;
    int t2 = 2;
    int t3 = 3;
    int t4 = 4;
    int t5 = 5;
    t1 + t2 + t3 + t4 + t5;
  });
  printf("14. multi: multi=%d\n", multi);

  int tern = 1;
  int tern_result = tern ? ({
    int t = 100;
    t * 2;
  })
                         : ({
                             int t = 200;
                             t * 2;
                           });
  printf("15. tern: tern_result=%d\n", tern_result);

  int arr_result = ({
    int arr[5];
    for (int i = 0; i < 5; i++) {
      arr[i] = i * i;
    }
    arr[0] + arr[1] + arr[2] + arr[3] + arr[4];
  });
  printf("16. array: arr_result=%d\n", arr_result);

  int ptr_result = ({
    int val = 42;
    int *p = &val;
    *p;
  });
  printf("17. pointer: ptr_result=%d\n", ptr_result);

  int fact = ({
    int n = 5;
    int result = 1;
    for (int i = 1; i <= n; i++) {
      result *= i;
    }
    result;
  });
  printf("18. fact: fact=%d\n", fact);

  int nested_if = ({
    int val = 7;
    int res = 0;
    if (val > 5) {
      if (val > 10) {
        res = 100;
      } else {
        res = 50;
      }
    } else {
      res = 0;
    }
    res;
  });
  printf("19. nested_if: nested_if=%d\n", nested_if);

  int loop_result = ({
    int total = 0;
    for (int i = 0; i < 10; i++) {
      if (i == 3)
        continue;
      if (i == 7)
        break;
      total += i;
    }
    total;
  });
  printf("20. loop: loop_result=%d\n", loop_result);

  return 0;
}
