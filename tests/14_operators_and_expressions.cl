// Feature Test 14: Operators (Arithmetic, Relational, Logical, Bitwise)

void main() {
  int a = 10;
  int b = 3;

  int sum = a + b;
  int diff = a - b;
  int prod = a * b;
  int quot = a / b;
  int rem = a % b;

  bool eq = (a == b);
  bool neq = (a != b);
  bool lt = (a < b);
  bool lte = (a <= b);
  bool gt = (a > b);
  bool gte = (a >= b);

  bool cond = (a > 0) && (b > 0) || !false;

  int bit_and = a & b;
  int bit_or = a | b;
  int bit_xor = a ^ b;
  int bit_not = ~a;
}
