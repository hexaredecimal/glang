import std.memory.owned;

struct First<T> {
  Second<T> next;
}

struct Second<T> {
  std::memory::Owned<First<T>> previous;
}

int main() {
  First<int> value = First<int>{};
  return 0;
}
