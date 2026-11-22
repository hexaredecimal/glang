T sum<T>(T... args) {
  T total;
  for (int i = 0; i < args.length; i++) {
    total += args[i];
  }
  return total;
}

int main() {
  int integers = sum(1, 2, 3, 4);
  double decimals = sum(0.5, 1.25, 2.25);
  if (integers != 10 || decimals != 4.0) {
    return 1;
  }
  return 0;
}
