int printf(const char *fmt, ...);

typedef struct {
  int x;
  int y;
} Bla;

int main() {
  Bla bla[3];
  bla[0].x = 10;
  bla[0].y = 20;
  bla[1].x = 30;
  bla[1].y = 40;
  bla[2].x = 50;
  bla[2].y = 60;

  printf("bla->x = %d\n", bla->x);
  printf("bla->y = %d\n", bla->y);
  printf("bla[0].x = %d\n", bla[0].x);
  printf("(bla+1)->x = %d\n", (bla + 1)->x);
  printf("(bla+2)->y = %d\n", (bla + 2)->y);
  printf("*(bla+1).x = %d\n", (*(bla + 1)).x);
  printf("1[bla].x = %d\n", 1 [bla].x);

  return 0;
}
