// Feature Test 15: Error Cases Verification (Invalid Enum Member / Unknown Symbol)

enum Directions {
  UP,
  DOWN
}

void main() {
  auto dir = Directions::INVALID_MEMBER;
}
