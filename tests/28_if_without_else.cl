


void main() {
  int result = if (true) { yield 100; };
  int unchanged = if (false) { yield 200; };

  int x = if (true) {
    yield 300;
  };

  if (false) {
    yield 400;
  }
}
