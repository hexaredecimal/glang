import std.memory.owned : Owned;

struct Foo {
  int x;
  Owned<int> ptr;
}

int main() {
  auto ownedResult = std::memory::fromValue(42);
  if (ownedResult.isErr()) {
    return 1;
  }
  auto owned = ownedResult.unwrap();
  Foo key = Foo{7, owned};
  int[Foo] values = [:];
  values[key] = 99;
  auto (foundValue, found) = values[key];
  std::memory::release(&owned);
  if (!found || foundValue != 99) {
    return 2;
  }
  return 0;
}
