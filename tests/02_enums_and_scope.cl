// Feature Test 02: Enums and Scope Resolution

enum Directions {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

enum Color {
  RED,
  GREEN,
  BLUE
}

void main() {
  Directions dir1 = Directions::UP;
  Directions dir2 = Directions::DOWN;
  Directions dir3 = Directions::LEFT;
  Directions dir4 = Directions::RIGHT;

  Color c1 = Color::RED;
  Color c2 = Color::GREEN;
  Color c3 = Color::BLUE;

  auto inferred_dir = Directions::LEFT;
}
