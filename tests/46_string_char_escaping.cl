int main() {
  const char* text = "line\nnext\0Z";
  if (text[4] != '\n' || text[9] != '\0' || text[10] != 'Z') {
    return 1;
  }

  char newline = '\n';
  char nullByte = '\0';
  char escapedQuote = '\'';
  char escapedSlash = '\\';
  char hexA = '\x41';
  char octalA = '\101';
  if (newline != text[4] || nullByte != text[9] ||
      escapedQuote != '\'' || escapedSlash != '\\' ||
      hexA != 'A' || octalA != 'A') {
    return 2;
  }

  const char* controls = "\a\b\f\r\t\v";
  if (controls[0] != '\a' || controls[1] != '\b' ||
      controls[2] != '\f' || controls[3] != '\r' ||
      controls[4] != '\t' || controls[5] != '\v') {
    return 3;
  }
  return 0;
}
