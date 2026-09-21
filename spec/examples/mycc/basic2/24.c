int printf(const char *fmt, ...);

typedef struct {
  int num;
  int is_float;
} Length;

typedef union {
  int i;
  Length length;
} Value;

typedef struct {
  int type;
  Value u;
} Property;

int main() {
  Property p = {.type = 1, .u.length = {.num = 42, .is_float = 0}};

  printf("type = %d, num = %d, is_float = %d\n", p.type, p.u.length.num,
         p.u.length.is_float);
  return 0;
}
