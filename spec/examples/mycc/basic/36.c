typedef unsigned long long size_t;

int main() {
  int x = 1 ? 'a' : (size_t)10;
  printf("%d\n", x);

  size_t new_capacity = 10;
  new_capacity = new_capacity ? new_capacity * 2 : 1024;
  printf("%d\n", new_capacity);
  return 0;
}
