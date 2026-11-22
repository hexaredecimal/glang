// Feature Test 01: Variables, Primitive Types, Const, and Auto Inference

[userLiteral] uint u(int v) => v as uint;
[userLiteral] float f(double v) => v as float;

void main() {
  int a = 42;
  uint b = 100u;
  bool c = true;
  char d = 'A';
  uchar e = 'B';
  short f_val = 10;
  ushort g = 20;
  long h = 100000;
  ulong i = 200000;
  float j = 3.14f;
  double k = 2.71828;

  const int MAX_VAL = 100;
  auto inferred_int = a;
  auto inferred_bool = c;
  auto inferred_const = MAX_VAL;
}
