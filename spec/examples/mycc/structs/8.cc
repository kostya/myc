struct Bla {
  int a;
  char b;
};

struct Point {
  int x;
  int y;
};

int main() {

  struct Bla bla = (struct Bla){1, 'a'};
  printf("bla %d %d\n", bla.a, bla.b);

  bla = (struct Bla){2, 'b'};
  printf("bla %d %d\n", bla.a, bla.b);

  printf("point %d %d\n", ((struct Point){10, 20}).x,
         ((struct Point){10, 20}).y);

  struct Point *p = &(struct Point){30, 40};
  printf("point ptr %d %d\n", p->x, p->y);

  struct Rect {
    struct Point origin;
    int w;
    int h;
  } r = (struct Rect){(struct Point){0, 0}, 100, 200};
  printf("rect %d %d %d %d\n", r.origin.x, r.origin.y, r.w, r.h);

  struct Point p2 = (struct Point){50};
  printf("point partial %d %d\n", p2.x, p2.y);

  struct Test {
    int a;
  };

  struct Test test = (struct Test){42};
  printf("test %d\n", test.a);

  return 0;
}
