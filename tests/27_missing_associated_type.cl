struct Iter<T> {
  type Inner = T::Inner;

  Inner* begin;
}

struct Empty {
  int value;
}

void main() {
  auto iter = Iter<Empty>{};
}
