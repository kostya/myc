int printf(const char *fmt, ...);

int test_string_escapes() {
  printf("  newline: %s\n", "hello\nworld");
  printf("  tab: %s\n", "hello\tworld");
  printf("  backslash: %s\n", "hello\\world");
  printf("  quote: %s\n", "hello\"world");
  printf("  mixed: %s\n", "line1\\nline2\nline3");

  char *csv = "\"point A\\n, \"\"0\"\"\",1.0,,2.0,\"[true\\n, 0]\",3.0";
  printf("  csv: %s\n", csv);
  printf("  octal: %s\n", "hello\101world");
  printf("  hex: %s\n", "hello\x41world");
  printf("  combo: %s\n", "\\\\n\\t\\\"\\101\\x41");

  return 0;
}

int main() {
  printf("=== String Escape Tests ===\n");
  test_string_escapes();
  printf("=== DONE ===\n");
  return 0;
}
