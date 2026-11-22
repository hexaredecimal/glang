import std.io.print : printf;

enum Foo {
  A,
  B,
  C
}

int classify(int n) {
  return switch (n) {
    default -> 0;
    case 1..5 -> 10;
    case 7 -> 20;
  };
}

int matchWithoutDefault(int n) {
  return switch (n) {
    case 1..5 -> n;
  };
}

void acceptFoo(Foo value) {
  if (value != Foo::A) {
    return;
  }
}

int sumAfter(int initial, int... values) {
  int total = initial;
  for (int i = 0; i < values.length; i++) {
    total += values[i];
  }
  return total;
}

int main() {
  if (classify(1) != 10 || classify(5) != 10 ||
      classify(6) != 0 || classify(7) != 20) {
    return 1;
  }
  if (matchWithoutDefault(3) != 3) {
    return 2;
  }

  acceptFoo(Foo::A);

  int total = 10.sumAfter(20, 30);
  if (total != 60) {
    return 3;
  }

  const char* format = "UFCS printf: %d\n";
  format.printf(47);
  return 0;
}
