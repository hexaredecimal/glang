void test<T>(T value) {
  T::testFunc(value);
}

void int::testFunc(int value) {
}

void main() {
  test(50);
}
