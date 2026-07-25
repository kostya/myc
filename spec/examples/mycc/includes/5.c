static int bla() { return 1; }
int external_bla();

int main() {
  printf("bla = %d\n", bla());
  printf("ext bla = %d\n", external_bla());
  return 0;
}
