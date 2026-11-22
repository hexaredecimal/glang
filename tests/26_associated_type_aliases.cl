struct Iter<T> {
  type InnerType = T::Inner;
  type IterType = T;

  InnerType* begin;
  uint size;
}

struct List<U> {
  type Inner = U;

  U* items;
}

void add<T>(List<T>* self, T value) {
}

void main() {
  auto list = List<int>{};
  add<int>(&list, 0);
  auto items = Iter<List<int>>{};
}
