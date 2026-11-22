import std.option;

std::Option<T> safeDiv<T>(T a, T b) {
  T zero;
  if (b == zero) {
    return std::none<T>();
  }
  return std::some(a / b);
}

void main() {
  auto intDiv = 50.safeDiv(2);
  int intResult = intDiv.unwrap_or() { ->
    return -1;
  };

  auto doubleDiv = 200.0.safeDiv(5.0);
  double doubleResult = doubleDiv.unwrap_or() { ->
    return -1;
  };

  if (intResult != 25 || doubleResult != 40.0) {
    return;
  }
}
