struct Quantity {
  int value;
}

[[infix_operator]]
int `%%`(Quantity left, Quantity right) => left.value + right.value;

[[no_custom_operators]]
int add(Quantity left, Quantity right) {
  return left %% right;
}

void main() {}
