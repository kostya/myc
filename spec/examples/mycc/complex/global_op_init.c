int printf(const char *fmt, ...);

static const int neg_val = -1;
static const int bnot_val = ~0;
static const int lnot_val = !5;

static const int arr[] = {~0, -1, !0, 5 + 3, 10 - 2};

int main() {
  printf("%d %d %d\n", neg_val, bnot_val, lnot_val);
  printf("%d %d %d %d %d\n", arr[0], arr[1], arr[2], arr[3], arr[4]);
  return 0;
}
