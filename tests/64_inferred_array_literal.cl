void sort<T>(T[] elements) {
  for (int i = 0; i < elements.length; ++i) {
    for (int j = 0; j < i; ++j) {
      T a = elements[i];
      T b = elements[j];
      if (a < b) {
        elements[i] = b;
        elements[j] = a;
      }
    }
  }
}

int main() {
  auto sorted = [50, 24, 73, 5, 900, 783];
  sort<int>(sorted);
  if (sorted[0] != 5 || sorted[5] != 900) {
    return 1;
  }
  return 0;
}
