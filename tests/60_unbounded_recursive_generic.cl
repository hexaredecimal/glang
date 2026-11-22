struct Expanding<T> {
  Expanding<T*> next;
}

int main() {
  Expanding<int> value = Expanding<int>{};
  return 0;
}
