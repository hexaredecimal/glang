struct Box<T> {
  T value;
}

int main() {
  Box<Box<int>> nested = Box<Box<int>>{Box<int>{42}};
  if (nested.value.value != 42) {
    return 1;
  }
  return 0;
}
