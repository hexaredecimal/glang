struct Point {
  int x;
  int y;
}

Point add(Point left, Point right) {
  return Point{x: left.x + right.x, y: left.y + right.y};
}
