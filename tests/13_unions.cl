// Feature Test 13: Union Declarations and Access

union Value {
  int i;
  char c;
  float f;
}

void main() {
  Value val;
  val.i = 42;
  int number = val.i;
}
