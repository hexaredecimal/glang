// Feature Test 20: Sizeof Unary Operator

struct Point {
  int x;
  int y;
}

void main() {
  ulong s1 = sizeof(int);
  ulong s2 = sizeof(double);
  ulong s3 = sizeof(Point);
  ulong s4 = sizeof(Point*);
  ulong s5 = sizeof(int[10]);

  int val = 42;
  ulong s6 = sizeof val;
  ulong s7 = sizeof(val + 10);
}
