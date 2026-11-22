// Regression Test 71: Structural binding and user-defined operators.
//
// Exercises positional struct binding through std::Pair, fixed-array binding,
// and declared prefix/infix/postfix operators.
//
// Run:
//   gcli build tests\71_structural_binding_and_operators.g --cpp -o build\test71.cpp
//   g++ -std=c++26 build\test71.cpp -o build\test71.exe
//   build\test71.exe

import std.container.pair;
import std.io.print;
import std.lib;

[[prefix_operator]]
T neg<T>(T value) => -value;

[[postfix_operator]]
T inc<T>(T value) => value + 1;

void main() {
  auto pair = 1 to 20;
  auto (first, second) = pair;
  if (first != 1 || second != 20) std::exit(1);

  auto (left, right) = [3, 4];
  if (left != 3 || right != 4) std::exit(2);

  int negated = neg 5;
  int incremented = negated inc;
  if (negated != -5 || incremented != -4) std::exit(3);
}
