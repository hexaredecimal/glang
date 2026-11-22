import std.geom._2d.point : Point, add;

[[extern]]
void c_log(const char* format, void*... args);

struct RefPair {
  int* x;
  int* y;
}

void collect(int... values) {}

void inspect(int[] values) {}

void build(int count) {
  int[count] dynamicValues;
  int[3] fixedValues;
  inspect(fixedValues);
  inspect([1, 2, 3]);
  collect(1, 2, 3);
  collect();

  auto first = Point{y: 2, x: 1};
  auto partial = Point{x: 4};
  auto sum = add(first, partial);
  int x = 5;
  int y = 6;
  auto references = RefPair{y: y, x: x};
}

void main() {
  build(3);
}
