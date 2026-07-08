static void bla(int freq[256]) { printf("%d %d\n", freq[100], freq[101]); }

int main() {
  int v[256] = {0};
  v[100] = 11;
  bla(v);
  return 0;
}
