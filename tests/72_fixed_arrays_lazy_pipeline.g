// Regression Test 72: Fixed arrays, array copy, and the lazy pipeline.
//
// Verifies raw C-array code generation, fixed-array .length and copy
// assignment, the declared |> operator, and List/Lazy pipeline helpers.
//
// Run:
//   gcli build tests\72_fixed_arrays_lazy_pipeline.g --cpp -o build\test72.cpp
//   g++ -std=c++26 build\test72.cpp -o build\test72.exe
//   build\test72.exe

import std.container.sequence;
import std.container.pair;
import std.io.print;
import std.lib;

[[infix_operator]]
T `|>` <T>(T value, T (*fn)(T)) => fn(value);

int twice(int value) => value * 2;

void main() {
  int[3] values = [10, 20, 30];
  values[1] = values[0] + values[2];
  if (values.length != 3 || values[1] != 40) std::exit(1);

  int[3] copied = values;
  if (copied[0] != 10 || copied[1] != 40 || copied[2] != 30) std::exit(2);

  int piped = 4 |> twice;
  if (piped != 8) std::exit(3);

  auto bools = [true, false]
      .to_lazy()
      |> map() { bool v -> return v; }
      |> filter() { bool v -> v != true; }
      |> to_list();
  if (bools.length != 1) std::exit(4);

  auto pairs = [1 to 20, 2 to 50, 4 to 70];
  if (pairs.length != 3 || pairs[1].first != 2 || pairs[1].second != 50) {
    std::exit(5);
  }
}
