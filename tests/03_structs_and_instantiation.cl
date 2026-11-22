// Feature Test 03: Struct Definitions, Instantiation, and Field Access

struct Point {
  int x;
  int y;
}

struct Rectangle {
  Point topLeft;
  Point bottomRight;
}

void main() {
  Point p1 = Point{10, 20};
  int px = p1.x;
  int py = p1.y;

  Rectangle rect = Rectangle{Point{0, 0}, Point{100, 50}};
  int rx = rect.topLeft.x;
  int ry = rect.bottomRight.y;
}
