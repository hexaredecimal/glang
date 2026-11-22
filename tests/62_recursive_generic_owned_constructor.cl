import std.memory.owned;

struct LinkedList<T> {
  T item;
  std::memory::Owned<LinkedList<T>> next;
}

std::memory::Owned<LinkedList<T>> LinkedList<T>::new(T item) {
  auto allocation = std::memory::make_owned<LinkedList<T>>();
  if (allocation.isErr()) {
    std::memory::Owned<LinkedList<T>> empty;
    return empty;
  }
  auto head = allocation.unwrap();
  head.ptr.item = item;
  head.ptr.next.ptr = nullptr;
  head.ptr.next.count = 0;
  return head;
}

int main() {
  auto list = LinkedList<int>::new(10);
  if (list.ptr.item != 10) {
    return 1;
  }
  std::memory::release(&list);
  return 0;
}
