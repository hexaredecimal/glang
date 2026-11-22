struct Foo<T> {
  type Inner = T;

  Inner value;
}

void doSomething<T>(Foo<T> foo) {
  Foo<T>::Inner inner = T::doStuff(foo.value);
  T::set(&foo.value, inner.x);
}

struct Bar {
  int x;
  int y;
}

Bar Bar::doStuff(Bar value) => value

void Bar::set(Bar* bar, int value) {
  bar.x = value;
  bar.y = bar.x * 2;
}

void main() {
  auto foo = Foo<Bar>{Bar{}};
  doSomething(foo);
}
