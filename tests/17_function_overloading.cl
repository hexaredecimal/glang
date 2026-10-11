// Feature Test 17: Function Overloading (Standalone, Static Methods, and Generic Overloads)

struct Calculator {}

int Calculator::add(int a, int b) => a + b
double Calculator::add(double a, double b) => a + b

int print_val(int val) => val
double print_val(double val) => val
const char* print_val(const char* val) => val

void main() {
  int r1 = print_val(42);
  double r2 = print_val(3.14);
  const char* r3 = print_val("hello");

  int c1 = Calculator::add(10, 20);
  double c2 = Calculator::add(1.5, 2.5);
}
