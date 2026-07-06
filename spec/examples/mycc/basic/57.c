void bla(int x) {
  int values[x];
  values[0] = 1;
  values[1] = 2;
  printf("%d, %d\n", values[0], values[1]);
}

int main() {
  bla(3);
  return 0;
}
