int printf(const char *fmt, ...);

typedef struct Bucket {
  int value;
  struct Bucket *next;
} Bucket;

typedef struct Table {
  Bucket *buckets;
  unsigned num_buckets;
} Table;

void test_buckets(Table *table, unsigned bkt) {
  Bucket *head = &(table->buckets[bkt]);
  printf("  head value: %d\n", head->value);
}

int main() {
  Bucket b1 = {10, 0};
  Bucket b2 = {20, 0};
  Bucket buckets_arr[] = {b1, b2};

  Table table;
  table.buckets = buckets_arr;
  table.num_buckets = 2;

  test_buckets(&table, 0);
  test_buckets(&table, 1);

  return 0;
}
