// Feature Test 09: Lambdas and Closures

void main() {
  int base = 10;
  auto add_base = {int x -> x + base; };
  int res = add_base(5);

  auto multiplier = {int a, int b -> a * b; };
  int product = multiplier(3, 4);

  auto a = { yield 5; };
  auto b = {int val -> a + val; };
  int sum = b(10);
}
