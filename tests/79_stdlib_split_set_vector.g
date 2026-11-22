// Regression Test 79: std.string split/join, std.container Set, and vectors.
//
// Verifies the zero-allocation split view, in-place splitting, join output,
// set insertion/removal, and Vec2/Vec3 operator overloads.
//
// Run:
//   gcli build tests\79_stdlib_split_set_vector.g --cpp -o build\test79.cpp
//   g++ -std=c++26 build\test79.cpp -o build\test79.exe
//   build\test79.exe

import std.string;
import std.container;
import std.geom.vector;
import std.math;
import std.lib;

void main() {
  if (split_count("a,b,c", ',') != 3) std::exit(1);
  if (split_count("", ',') != 1) std::exit(2);
  if (split_count("a,,c", ',') != 3) std::exit(3);

  auto view = split_view("one,two,three", ',');
  auto (first, firstLength, firstFound) = split_next(&view);
  if (!firstFound || firstLength != 3) std::exit(4);
  if (first[0] != 'o' || first[1] != 'n' || first[2] != 'e') std::exit(5);

  auto joined = join(view, "-");
  if (compare_strings(joined.to_string(), "two-three") != 0) std::exit(6);

  char[32] buffer = ['a', ',', 'b', ',', 'c', '\0'];
  auto parts = split(&buffer[0], ',');
  if (parts.length != 3) std::exit(7);
  if (compare_strings(parts[0], "a") != 0) std::exit(8);
  if (compare_strings(parts[2], "c") != 0) std::exit(9);

  auto rebuilt = join(parts, "|");
  if (compare_strings(rebuilt.to_string(), "a|b|c") != 0) std::exit(10);

  auto set = make_set<int>();
  if (!set.add(1)) std::exit(11);
  if (set.add(1)) std::exit(12);
  if (!set.add(2)) std::exit(13);
  if (!set.contains(2)) std::exit(14);
  if (set.len() != 2) std::exit(15);
  if (!set.remove(1)) std::exit(16);
  if (set.remove(1)) std::exit(17);
  if (set.contains(1)) std::exit(18);
  if (set.len() != 1) std::exit(19);
  if (!set.add(1)) std::exit(20);
  if (set.len() != 2) std::exit(21);
  set.clear();
  if (!set.is_empty()) std::exit(22);

  Vec2 a = vec2(1.0, 2.0);
  Vec2 b = vec2(3.0, 4.0);

  Vec2 sum = a + b;
  if (sum.x != 4.0 || sum.y != 6.0) std::exit(23);

  Vec2 difference = b - a;
  if (difference.x != 2.0 || difference.y != 2.0) std::exit(24);

  Vec2 negated = -a;
  if (negated.x != -1.0 || negated.y != -2.0) std::exit(25);

  Vec2 scaled = a * 3.0;
  if (scaled.x != 3.0 || scaled.y != 6.0) std::exit(26);

  Vec2 scaledLeft = 3.0 * a;
  if (scaledLeft.x != 3.0 || scaledLeft.y != 6.0) std::exit(27);

  Vec2 halved = b / 2.0;
  if (halved.x != 1.5 || halved.y != 2.0) std::exit(28);

  if ((a * b) != 11.0) std::exit(29);
  if (magnitude_squared(vec2(3.0, 4.0)) != 25.0) std::exit(30);
  if (abs(magnitude(vec2(3.0, 4.0)) - 5.0) > 0.0001) std::exit(31);

  Vec2 unit = normalized(vec2(3.0, 4.0));
  if (abs(unit.x - 0.6) > 0.0001 || abs(unit.y - 0.8) > 0.0001) std::exit(32);

  Vec3 c = vec3(1.0, 0.0, 0.0);
  Vec3 d = vec3(0.0, 1.0, 0.0);
  Vec3 crossProduct = c % d;
  if (crossProduct.x != 0.0 || crossProduct.y != 0.0 ||
      crossProduct.z != 1.0) {
    std::exit(33);
  }
  if (cross(d, c).z != -1.0) std::exit(34);
  if (dot(c, d) != 0.0) std::exit(35);

  Vec3 sum3 = c + d;
  if (sum3.x != 1.0 || sum3.y != 1.0 || sum3.z != 0.0) std::exit(36);
}
