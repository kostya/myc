int printf(const char *fmt, ...);

struct Outer {
  union {
    int x;
    struct {
      int y;
      char z;
    };
  };
  struct {
    union {
      int w;
      float q;
    };
  };
};

int main() {
  struct Outer obj;

  obj.x = 10;
  printf("obj.x = %d\n", obj.x);

  obj.y = 20;
  obj.z = 'A';
  printf("obj.y = %d, obj.z = %c\n", obj.y, obj.z);

  obj.x = 100;
  printf("After obj.x = 100: obj.x = %d, obj.y = %d\n", obj.x, obj.y);

  obj.w = 30;
  printf("obj.w = %d\n", obj.w);

  obj.q = 3.14f;
  printf("obj.q = %f\n", obj.q);

  obj.w = 40;
  printf("After obj.w = 40: obj.w = %d, obj.q = %f\n", obj.w, obj.q);

  printf("sizeof(struct Outer) = %zu\n", sizeof(struct Outer));

  struct Outer *p = &obj;
  p->x = 50;
  printf("p->x = %d\n", p->x);

  p->y = 60;
  p->z = 'B';
  printf("p->y = %d, p->z = %c\n", p->y, p->z);

  p->w = 70;
  printf("p->w = %d\n", p->w);

  p->q = 2.71f;
  printf("p->q = %f\n", p->q);

  return 0;
}
