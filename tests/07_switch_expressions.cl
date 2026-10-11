// Feature Test 07: Switch Expressions and Pattern Matching

enum Directions {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

const char* dir_to_string(Directions dir) {
  return switch (dir) {
    case Directions::UP    -> "UP";
    case Directions::DOWN  -> "DOWN";
    case Directions::LEFT  -> "LEFT";
    case Directions::RIGHT -> "RIGHT";
  };
}

int evaluate_bool(bool flag) {
  return switch (flag) {
    case false -> 0;
    case true  -> { yield 1; }
  };
}

void main() {
  const char* s = dir_to_string(Directions::UP);
  int val = evaluate_bool(true);
}
