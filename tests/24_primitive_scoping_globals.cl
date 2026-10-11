// Feature Test 24: Scoping Functions and Global Variables on Primitive Types

int g_base = 10;
double g_scale = 1.5;

int doubleVal(int x) => x * 2;
int addBase(int x) => x + g_base;

int compute(int val) {
  int localBase = 5;
  int step1 = doubleVal(val);
  int step2 = addBase(step1);
  return step2 + localBase;
}

void main() {
  int res1 = compute(20);

  // Nested scope test
  int outer = 100;
  {
    int inner = outer + g_base;
    g_base = inner;
  }

  int res2 = g_base;
}
