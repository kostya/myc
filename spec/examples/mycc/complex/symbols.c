int printf(const char *fmt, ...);

int main(void) {
  printf("\"Hello\nWorld\"\n");
  printf("\"Tab\tseparated\"\n");
  printf("\"Backslash: \\\"\n");
  printf("\"Quote: \"test\"\"\n");
  printf("\"Hex bytes: Hello\"\n");
  printf("\"Hex bytes: ABC\"\n");
  printf("\"Hex braces: HI\"\n");
  printf("\"Mixed: Hello\nWorld!\"\n");
  printf("\"Octal: ABC\"\n");
  printf("\"Octal braces: DE\"\n");
  printf("\"Octal space:  Hello!\"\n");
  printf("\"Octal two: HI\"\n");
  printf("\"Unicode: Привет\"\n");
  printf("\"Unicode short: Hello\"\n");
  printf("\"Unicode omega: Ω\"\n");
  printf("\"Unicode arrow: →\"\n");
  printf("\"Unicode braces: ABC\"\n");
  printf("\"Emoji: 😀\"\n");
  printf("\"Chinese: 你好\"\n");
  printf("\"Complex: 👋 Hello 👋\"\n");
  printf("\"Clef: 𝄞\"\n");
  printf("\"MAX: 􏿿\"\n");
  printf("\"Mixed: Hello! World?\nNew line\n\"\n");
  printf("\"JSON: {\"key\": \"value\"}\"\n");
  printf("\"Path: C:\\Users\\Name\\file.txt\"\n");
  printf("\"Tabbed:\tcol1\tcol2\tcol3\"\n");
  printf("\"Single: A\"\n");
  printf("\"Digits: 123\"\n");
  printf("\"Space:  \"\n");
  return 0;
}
