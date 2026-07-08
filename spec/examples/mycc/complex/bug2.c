int printf(const char *fmt, ...);

#define TAKE_ADDR(arr, idx) &(arr[idx])

typedef struct Bucket {
  int value;
} Bucket;

void test_macro(Bucket *buckets, unsigned bkt) {
  Bucket *head = TAKE_ADDR(buckets, bkt);
  printf("  head value: %d\n", head->value);
}

int main() {
  Bucket arr[2];
  arr[0].value = 10;
  arr[1].value = 20;
  test_macro(arr, 0);
  test_macro(arr, 1);
  return 0;
}
