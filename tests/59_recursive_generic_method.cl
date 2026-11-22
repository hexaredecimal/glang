import std.memory.owned;

struct LinkedList<T> {
  T item;
  std::memory::Owned<LinkedList<T>> next;
}

std::memory::Owned<LinkedList<T>> LinkedList<T>::new(T item) {
  std::memory::Owned<LinkedList<T>> result;
  return result;
}

int main() {
  auto list = LinkedList<int>::new(10);
  return 0;
}
