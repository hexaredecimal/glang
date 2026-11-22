import std.memory.owned;

struct Foo {
  std::memory::Owned<Foo> next;
}

int main() {
  return 0;
}
