int printf(const char *fmt, ...);

static const char *PATTERN0 = "(?i)etc/passwd|wp-admin|\\.\\./";

static const char *PATTERN[] = {"(?i)etc/passwd|wp-admin|\\.\\./",
                                "/api/[^ \" ]+"};

int test_escape_backslash() {

  const char *regex = "(?i)etc/passwd|wp-admin|\\.\\./";
  printf("  regex: %s\n", regex);

  printf("  PATTERN0: %s\n", PATTERN0);
  printf("  PATTERN: %s\n", PATTERN[0]);
  printf("  PATTERN2: %s\n", PATTERN[1]);

  const char *dots = "hello\\.\\.world";
  printf("  dots: %s\n", dots);

  const char *normal = "line1\\nline2\\t tab";
  printf("  normal: %s\n", normal);

  const char *mixed = "path\\to\\\\file\\.txt";
  printf("  mixed: %s\n", mixed);

  return 0;
}

int main() {
  printf("=== Escape Backslash Tests ===\n");
  test_escape_backslash();
  printf("=== DONE ===\n");
  return 0;
}
