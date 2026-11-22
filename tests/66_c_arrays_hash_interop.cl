struct ArrayKey {
  int[3] values;
}

int sumFixed(int[3] values) {
  int total = 0;
  for (int i = 0; i < values.length; ++i) {
    total += values[i];
  }
  return total;
}

[[extern, c_abi]]
int c_array_probe(int[3] values);

int main() {
  int[3] values = [10, 20, 30];
  if (values.length != 3 || sizeof(int[3]) != 3 * sizeof(int) ||
      sumFixed(values) != 60) {
    return 1;
  }
  int[3] copied = values;
  if (copied[0] != 10 || copied[2] != 30) {
    return 2;
  }
  copied = [1, 2, 3];
  if (copied[0] != 1 || copied[2] != 3) {
    return 3;
  }

  int[ArrayKey] byArray = [:];
  byArray[ArrayKey{[1, 2, 3]}] = 42;
  auto (foundValue, found) = byArray[ArrayKey{[1, 2, 3]}];
  if (!found || foundValue != 42) {
    return 4;
  }
  return 0;
}
