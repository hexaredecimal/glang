// Feature Test 06: Functions and Arrow Expression Bodies

int add(int a, int b) {
  return a + b;
}

int square(int x) => x * x

bool is_positive(int num) => num > 0

void main() {
  int sum = add(15, 27);
  int sq = square(6);
  bool pos = is_positive(sq);
}
