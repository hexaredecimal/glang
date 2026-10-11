struct Foo<T> {
  type Inner = T;
  Inner x;
  Inner y;
}

struct Pair<T> {
  T first;
  T second;
}

T identity<T>(T value) => value
T add_gen<T>(T a, T b) => a + b

void showDef(int d) {}
void showDef2(const char* s) {}

void main() {
  auto foo = Foo{};
  foo.x -= 10;
  showDef(foo.x);
  Foo<int>::Inner x = foo.x;

  auto callBound = Foo{};
  showDef(callBound.x);

  auto initialized = Foo{40, 30};
  int y = initialized.y;

  auto pair = Pair{100, 200};
  int second = pair.second;
  int id = identity<int>(42);
  int sum = add_gen(10, 20);
}
