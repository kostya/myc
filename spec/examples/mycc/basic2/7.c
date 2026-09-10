int printf(const char *fmt, ...);

typedef struct {
  int x;
} Bla;

int main() {
  Bla bla[1];
  bla->x = 10;
  printf("%d %d %d\n", bla->x, bla[0].x, (*(bla + 0)).x);
  return 0;
}
