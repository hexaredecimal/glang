// Regression Test 74: Imported operators and tuple shorthand functions.
//
// Verifies that prefix, infix, and postfix operators declared in an imported
// module are usable without redeclaration, that operators are imported
// wholesale even when the import has a selective symbol list, and that
// shorthand functions may take or return tuples.
//
// Run:
//   gcli build tests\74_imported_operators.g --cpp -o build\test74.cpp
//   g++ -std=c++26 build\test74.cpp -o build\test74.exe
//   build\test74.exe

import tests.support.imported_operators: split;
import std.container.pair;
import std.lib;

void main() {
  // Only `split` is named, but all three operators come with the module.
  int prefixed = increment 4;
  if (prefixed != 5) std::exit(1);

  int postfixed = 6 doubled;
  if (postfixed != 12) std::exit(2);

  int infixed = 10 average 20;
  if (infixed != 15) std::exit(3);

  // The `to` operator comes from std.container.pair.
  auto pair = 1 to 9;
  if (pair.first != 1 || pair.second != 9) std::exit(4);

  // Tuple-returning shorthand declared in the imported module.
  auto (tens, ones) = split(47);
  if (tens != 4 || ones != 7) std::exit(5);

  // Tuple-returning arrow form of the pair projection.
  auto (first, second) = to_tuple(pair);
  if (first != 1 || second != 9) std::exit(6);

  // Tuple parameter with a shorthand body.
  int sum = sum_pair((3, 4));
  if (sum != 7) std::exit(7);

  auto pair2 = to_pair((5, 6));
  if (pair2.first != 5 || pair2.second != 6) std::exit(8);
}
