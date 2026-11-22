import std.memory.owned;

struct LinkedList<T> {
  T item;
  std::memory::Owned<LinkedList<T>> next;
}

int main() {
  LinkedList<int> list = LinkedList<int>{};
  return 0;
}
