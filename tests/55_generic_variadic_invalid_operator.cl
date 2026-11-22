struct NotAddable {}

T sum<T>(T... args) {
  T total;
  for (int i = 0; i < args.length; i++) {
    total += args[i];
  }
  return total;
}

int main() {
  auto unsupported = sum(NotAddable{}, NotAddable{});
  return 0;
}
