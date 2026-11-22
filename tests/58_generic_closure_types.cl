T applyTwice<T>(T value) {
  auto duplicate = {T item -> item + item;};
  return duplicate(value);
}

T applyCallback<T>(T value, (T)->T callback) {
  return callback(value);
}

int main() {
  int doubled = applyTwice(4);
  int incremented = applyCallback(4, {int item -> item + 1;});
  if (doubled != 8 || incremented != 5) {
    return 1;
  }
  return 0;
}
