struct Foo<T> {
  T value;
}

struct Pair<A, B> {
  A first;
  B second;
}

struct Nested<T> {
  Foo<T> child;
}

void consumeIntFoo(Foo<int> foo) {
  if (foo.value < 0) {
    return;
  }
}

void consumeIntFooPointer(Foo<int>* foo) {
  if (foo.value < 0) {
    return;
  }
}

void consumeByContext<T>(Foo<T> foo, T expected) {
  if (foo.value != expected) {
    return;
  }
}

void main() {
  auto foo = Foo{};
  foo.value = 42;
  int value = foo.value;
  if (value != 42) {
    return;
  }

  auto pair = Pair{};
  pair.first = 7;
  pair.second = true;
  if (pair.first != 7 || !pair.second) {
    return;
  }

  auto nested = Nested{};
  nested.child = Foo{99};
  int nestedValue = nested.child.value;
  if (nestedValue != 99) {
    return;
  }

  auto fromInitializer = Foo{123};
  if (fromInitializer.value != 123) {
    return;
  }

  auto fromConcreteFunction = Foo{};
  consumeIntFoo(fromConcreteFunction);
  int concreteValue = fromConcreteFunction.value;
  if (concreteValue != 0) {
    return;
  }

  auto fromPointerFunction = Foo{};
  consumeIntFooPointer(&fromPointerFunction);
  int pointerValue = fromPointerFunction.value;
  if (pointerValue != 0) {
    return;
  }

  auto fromGenericFunction = Foo{};
  consumeByContext(fromGenericFunction, 17);
  int genericValue = fromGenericFunction.value;
  if (genericValue != 17) {
    return;
  }
}
