int printf(const char *fmt, ...);

struct Data {
  int global_x;
  int global_y;
};

union Value {
  int i;
  float f;
};

static int test_shadow_both() {
  struct Data {
    int local_x;
    int local_y;
    int local_z;
  };

  union Value {
    long long big;
    double d;
  };

  struct Data d;
  d.local_x = 1;
  d.local_y = 2;
  d.local_z = 3;

  union Value v;
  v.big = 0x123456789ABCDEF0LL;

  printf("shadow_both: d.local_x=%d, d.local_y=%d, d.local_z=%d\n", d.local_x,
         d.local_y, d.local_z);
  printf("shadow_both: v.big=%lld\n", v.big);

  return 0;
}

static int test_shadow_struct() {
  struct Data {
    int a;
    int b;
  };

  struct Data d;
  d.a = 10;
  d.b = 20;

  printf("shadow_struct: d.a=%d, d.b=%d\n", d.a, d.b);

  return 0;
}

static int test_shadow_union() {
  union Value {
    int a;
    int b;
    int c;
  };

  union Value v;
  v.a = 42;

  printf("shadow_union: v.a=%d, v.b=%d, v.c=%d\n", v.a, v.b, v.c);

  return 0;
}

static int test_shadow_size() {
  struct Data {
    char c1;
    char c2;
    char c3;
    char c4;
    char c5;
    char c6;
    char c7;
    char c8;
  };

  struct Data d;
  d.c1 = 'A';
  d.c2 = 'B';
  d.c8 = 'Z';

  printf("shadow_size: d.c1=%c, d.c2=%c, d.c8=%c\n", d.c1, d.c2, d.c8);

  return 0;
}

static int test_shadow_nested() {
  struct Data {
    int id;
    union {
      int n1;
      char n2[4];
    };
    struct {
      short s1;
      short s2;
    };
  };

  struct Data o;
  o.id = 999;
  o.n1 = 0x11223344;

  printf("shadow_nested: o.id=%d, o.n1=0x%x\n", o.id, o.n1);

  return 0;
}

static int test_global() {
  struct Data d;
  d.global_x = 1000;
  d.global_y = 2000;

  union Value v;
  v.i = 12345;

  printf("global: d.global_x=%d, d.global_y=%d\n", d.global_x, d.global_y);
  printf("global: v.i=%d\n", v.i);

  return 0;
}

static int test_shadow_different_func() {
  struct Data {
    int different_x;
    int different_y;
    int different_z;
    int different_w;
  };

  struct Data d;
  d.different_x = 100;
  d.different_y = 200;
  d.different_z = 300;
  d.different_w = 400;

  printf("shadow_different: d.different_x=%d, d.different_y=%d, "
         "d.different_z=%d, d.different_w=%d\n",
         d.different_x, d.different_y, d.different_z, d.different_w);

  return 0;
}

static int test_shadow_array() {
  struct Data {
    int arr[5];
    int size;
  };

  struct Data d;
  for (int i = 0; i < 5; i++) {
    d.arr[i] = i * 10;
  }
  d.size = 5;

  printf("shadow_array: d.arr[0]=%d, d.arr[4]=%d, d.size=%d\n", d.arr[0],
         d.arr[4], d.size);

  return 0;
}

static int test_shadow_ptr() {
  struct Data {
    int *ptr;
    int value;
  };

  int x = 42;
  struct Data d;
  d.ptr = &x;
  d.value = 100;

  printf("shadow_ptr: *d.ptr=%d, d.value=%d\n", *d.ptr, d.value);

  return 0;
}

static int add(int a, int b) { return a + b; }

static int test_shadow_fnptr() {
  struct Data {
    int (*fn)(int, int);
    int result;
  };

  struct Data d;
  d.fn = add;
  d.result = d.fn(10, 20);

  printf("shadow_fnptr: d.result=%d\n", d.result);

  return 0;
}

static int test_inner_shadow() {
  struct Data {
    int x;
    int y;
  };

  struct Data data;
  data.x = 10;
  data.y = 20;
  printf("test_inner_shadow: %d, %d\n", data.x, data.y);

  if (1) {
    struct Data {
      int a;
      int b;
    };

    struct Data data2;
    data2.a = 1;
    data2.b = 2;
    printf("test_inner_shadow: %d, %d, %d, %d\n", data2.a, data2.b, data.x, data.y);
  }

  return 0;
}

int main() {
  printf("=== Test 1: Shadow both struct and union ===\n");
  test_shadow_both();

  printf("=== Test 2: Shadow struct only ===\n");
  test_shadow_struct();

  printf("=== Test 3: Shadow union only ===\n");
  test_shadow_union();

  printf("=== Test 4: Shadow with different size ===\n");
  test_shadow_size();

  printf("=== Test 5: Shadow with nested union ===\n");
  test_shadow_nested();

  printf("=== Test 6: Use global types ===\n");
  test_global();

  printf("=== Test 7: Shadow in different function ===\n");
  test_shadow_different_func();

  printf("=== Test 8: Shadow with array ===\n");
  test_shadow_array();

  printf("=== Test 9: Shadow with pointer ===\n");
  test_shadow_ptr();

  printf("=== Test 10: Shadow with function pointer ===\n");
  test_shadow_fnptr();

  printf("=== Test 11: Shadow inner ===\n");
  test_inner_shadow();

  return 0;
}
