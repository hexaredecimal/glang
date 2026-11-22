struct Test<T> {
  T a;
}

void run<T>(Test<T> a, Test<T> b) {
  if (a.a > b.a) {
    return;
  }
}

void test<T>(Test<T> ... args) {
}

void main() {
  Test<int> first = Test<int>{10};
  Test<int> second = Test<int>{5};
  run(first, second);
  test(first, second);
  test(first);
  Test<int>[] pair = [first, second];
  test(pair);
  test([first, second]);

  int x = 0;
  if (true)
    x = 5;
  else
    x = 1;

  if (x > 5)
    x = 10;
  else if (x < 5)
    x = 9;
  else
    x = 0;

  x = if (x > 5){ yield 6;}
  else if (x < 5)
    yield 9;
  else
    yield x;
}
