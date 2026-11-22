import std.string.search;

[[infix_operator]]
bool `==`(int left, int right) => false;

[[no_custom_operators]]
bool is_null(const char* value) {
  return value == nullptr;
}

[[no_custom_operators]]
bool generic_equal<T>(T left, T right) {
  return left == right;
}

int main() {
  if (!std::string::equals(nullptr, nullptr)) {
    return 1;
  }
  if (std::string::equals(nullptr, "text")) {
    return 2;
  }
  if (!is_null(nullptr)) {
    return 3;
  }
  if (!generic_equal<int>(4, 4)) {
    return 4;
  }
  return 0;
}
