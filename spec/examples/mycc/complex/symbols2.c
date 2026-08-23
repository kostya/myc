#include <stdio.h>

int main(void) {
  printf("\"Hello\nWorld\"\n");
  printf("\"Tab\tseparated\"\n");
  printf("\"Backslash: \\\"\n");
  printf("\"Quote: \"test\"\"\n");
  printf("\"Hex bytes: \x48\x65\x6C\x6C\x6F\"\n");
  printf("\"Hex bytes: \x41\x42\x43\"\n");
  printf("\"Hex braces: \x48\x49\"\n");
  printf("\"Mixed: Hello\nWorld!\"\n");
  printf("\"Octal: \101\102\103\"\n");
  printf("\"Octal braces: \104\105\"\n");
  printf("\"Octal space: \40Hello!\"\n");
  printf("\"Octal two: \110\111\"\n");
  printf("\"Unicode: \xD0\x9F\xD1\x80\xD0\xB8\xD0\xB2\xD0\xB5\xD1\x82\"\n");
  printf("\"Unicode short: \x48\x65\x6C\x6C\x6F\"\n");
  printf("\"Unicode omega: \xCE\xA9\"\n");
  printf("\"Unicode arrow: \xE2\x86\x92\"\n");
  printf("\"Unicode braces: \x41\x42\x43\"\n");
  printf("\"Emoji: \xF0\x9F\x98\x80\"\n");
  printf("\"Chinese: \xE4\xBD\xA0\xE5\xA5\xBD\"\n");
  printf("\"Complex: \xF0\x9F\x91\x8B Hello \xF0\x9F\x91\x8B\"\n");
  printf("\"Clef: \xF0\x9D\x84\x9E\"\n");
  printf("\"MAX: \xF4\x8F\xBF\xBF\"\n");
  printf("\"Mixed: Hello! World?\nNew line\n\"\n");
  printf("\"JSON: {\"key\": \"value\"}\"\n");
  printf("\"Path: C:\\Users\\Name\\file.txt\"\n");
  printf("\"Tabbed:\tcol1\tcol2\tcol3\"\n");
  printf("\"Single: A\"\n");
  printf("\"Digits: 123\"\n");
  printf("\"Space:  \"\n");
  return 0;
}
