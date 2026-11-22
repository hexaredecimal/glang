// Regression Test 85: std.geom Rect and std.string padding helpers.
//
// Verifies rectangle bounds, containment, intersection/union, operators, and
// the pad/zfill/truncate/repeat string utilities.
//
// Run:
//   gcli build tests\85_stdlib_rect_pad.g --cpp -o build\test85.cpp
//   g++ -std=c++26 build\test85.cpp -o build\test85.exe
//   build\test85.exe

import std.geom;
import std.string;
import std.math;
import std.lib;

bool rect_equals(Rect left, Rect right) =>
    left.x == right.x && left.y == right.y && left.width == right.width &&
    left.height == right.height;

void main() {
  Rect rect = make_rect(10.0, 20.0, 30.0, 40.0);
  if (rect_left(rect) != 10.0 || rect_top(rect) != 20.0) std::exit(1);
  if (rect_right(rect) != 40.0 || rect_bottom(rect) != 60.0) std::exit(2);
  if (rect_center_x(rect) != 25.0 || rect_center_y(rect) != 40.0) std::exit(3);
  if (rect_area(rect) != 1200.0 || rect_perimeter(rect) != 140.0) std::exit(4);
  if (rect_is_empty(rect)) std::exit(5);
  if (!rect_is_empty(make_rect(0.0, 0.0, 0.0, 5.0))) std::exit(6);
  if (!rect_is_empty(make_rect(0.0, 0.0, 5.0, -1.0))) std::exit(7);

  // Containment.
  if (!rect_contains(rect, 10.0, 20.0)) std::exit(8);
  if (!rect_contains(rect, 40.0, 60.0)) std::exit(9);
  if (!rect_contains(rect, 25.0, 40.0)) std::exit(10);
  if (rect_contains(rect, 9.99, 20.0)) std::exit(11);
  if (rect_contains(rect, 25.0, 60.01)) std::exit(12);
  if (!rect_contains_rect(rect, make_rect(15.0, 25.0, 10.0, 10.0))) {
    std::exit(13);
  }
  if (rect_contains_rect(rect, make_rect(30.0, 50.0, 20.0, 20.0))) {
    std::exit(14);
  }
  if (!rect_contains_rect(rect, make_rect(100.0, 100.0, 0.0, 0.0))) {
    std::exit(15);
  }

  // Intersection and union.
  Rect overlap = make_rect(35.0, 50.0, 10.0, 10.0);
  if (!rect_intersects(rect, overlap)) std::exit(16);
  if (rect_intersects(rect, make_rect(40.0, 20.0, 10.0, 10.0))) std::exit(17);
  if (rect_intersects(rect, make_rect(100.0, 100.0, 5.0, 5.0))) std::exit(18);
  if (rect_intersects(rect, make_rect(0.0, 0.0, 0.0, 0.0))) std::exit(19);

  auto (intersection, hasIntersection) = rect_intersection(rect, overlap);
  if (!hasIntersection) std::exit(20);
  if (!rect_equals(intersection, make_rect(35.0, 50.0, 5.0, 10.0))) {
    std::exit(21);
  }
  auto (disjoint, hasDisjoint) =
      rect_intersection(rect, make_rect(100.0, 100.0, 5.0, 5.0));
  if (hasDisjoint) std::exit(22);
  if (!rect_equals(disjoint, make_rect(0.0, 0.0, 0.0, 0.0))) std::exit(23);

  Rect combined = rect_union(rect, overlap);
  if (!rect_equals(combined, make_rect(10.0, 20.0, 35.0, 40.0))) std::exit(24);
  Rect empty = make_rect(0.0, 0.0, 0.0, 0.0);
  if (!rect_equals(rect_union(empty, rect), rect)) std::exit(25);
  if (!rect_equals(rect_union(rect, empty), rect)) std::exit(26);

  // Corner normalization and transforms.
  Rect normalized = rect_from_points(10.0, 10.0, 0.0, 0.0);
  if (!rect_equals(normalized, make_rect(0.0, 0.0, 10.0, 10.0))) {
    std::exit(27);
  }
  if (!rect_equals(rect_from_points(0.0, 8.0, 4.0, 2.0),
                   make_rect(0.0, 2.0, 4.0, 6.0))) {
    std::exit(28);
  }
  if (!rect_equals(rect_inflate(rect, 5.0),
                   make_rect(5.0, 15.0, 40.0, 50.0))) {
    std::exit(29);
  }
  if (!rect_equals(rect_inflate(rect, -10.0),
                   make_rect(20.0, 30.0, 10.0, 20.0))) {
    std::exit(30);
  }
  if (!rect_equals(rect_translate(rect, 5.0, -5.0),
                   make_rect(15.0, 15.0, 30.0, 40.0))) {
    std::exit(31);
  }
  if (!rect_equals(rect_scale(rect, 2.0),
                   make_rect(20.0, 40.0, 60.0, 80.0))) {
    std::exit(32);
  }

  // Rectangle operators.
  Rect operatorUnion = rect + make_rect(0.0, 0.0, 50.0, 70.0);
  if (!rect_equals(operatorUnion, make_rect(0.0, 0.0, 50.0, 70.0))) {
    std::exit(33);
  }
  Rect operatorScaled = rect * 3.0;
  if (!rect_equals(operatorScaled, make_rect(30.0, 60.0, 90.0, 120.0))) {
    std::exit(34);
  }
  if (!(rect < operatorScaled)) std::exit(35);
  if (operatorScaled < rect) std::exit(36);

  // Padding.
  StringBuilder padded = pad_left("7", 3, '0');
  if (compare_strings(padded.to_string(), "007") != 0) std::exit(37);
  padded = pad_left("abcdef", 3, '.');
  if (compare_strings(padded.to_string(), "abcdef") != 0) std::exit(38);
  padded = pad_start("x", 2, '.');
  if (compare_strings(padded.to_string(), ".x") != 0) std::exit(39);
  padded = pad_right("ab", 4, '.');
  if (compare_strings(padded.to_string(), "ab..") != 0) std::exit(40);
  padded = pad_right("abcdef", 2, '.');
  if (compare_strings(padded.to_string(), "abcdef") != 0) std::exit(41);
  padded = pad_end("x", 2, '.');
  if (compare_strings(padded.to_string(), "x.") != 0) std::exit(42);
  padded = pad_center("ab", 5, '-');
  if (compare_strings(padded.to_string(), "-ab--") != 0) std::exit(43);
  padded = pad_center("ab", 6, '-');
  if (compare_strings(padded.to_string(), "--ab--") != 0) std::exit(44);
  padded = pad_center("abc", 3, '-');
  if (compare_strings(padded.to_string(), "abc") != 0) std::exit(45);

  padded = zfill("42", 4);
  if (compare_strings(padded.to_string(), "0042") != 0) std::exit(46);
  padded = zfill("-42", 5);
  if (compare_strings(padded.to_string(), "-0042") != 0) std::exit(47);
  padded = zfill("+7", 4);
  if (compare_strings(padded.to_string(), "+007") != 0) std::exit(48);
  padded = zfill("-42", 2);
  if (compare_strings(padded.to_string(), "-42") != 0) std::exit(49);
  padded = zfill("", 3);
  if (compare_strings(padded.to_string(), "000") != 0) std::exit(50);

  padded = truncate_width("abcdef", 3);
  if (compare_strings(padded.to_string(), "abc") != 0) std::exit(51);
  padded = truncate_width("ab", 5);
  if (compare_strings(padded.to_string(), "ab") != 0) std::exit(52);
  padded = truncate_width("abc", 0);
  if (compare_strings(padded.to_string(), "") != 0) std::exit(53);

  padded = repeat_text("ab", 3);
  if (compare_strings(padded.to_string(), "ababab") != 0) std::exit(54);
  padded = repeat_text("ab", 0);
  if (compare_strings(padded.to_string(), "") != 0) std::exit(55);
  padded = repeat_text("ab", -2);
  if (compare_strings(padded.to_string(), "") != 0) std::exit(56);
  padded = repeat_text("", 5);
  if (compare_strings(padded.to_string(), "") != 0) std::exit(57);
}
