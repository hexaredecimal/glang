// Regression Test 77: Custom operator declarations and imports.
//
// Verifies that `<`, `<=`, `??`, `%%`, and `<=>` can be declared locally and
// imported from another module, alongside identifier-named and symbol-named
// prefix, infix, and postfix operators.
//
// Run:
//   gcli build tests\77_custom_operator_declarations.g --cpp -o build\test77.cpp
//   g++ -std=c++26 build\test77.cpp -o build\test77.exe
//   build\test77.exe

import tests.support.custom_operators: combine;
import std.lib;

struct Local {
  int value;
}

[[infix_operator]]
bool `<`(Local left, Local right) => left.value < right.value;

[[infix_operator]]
bool `<=`(Local left, Local right) => left.value <= right.value;

[[infix_operator]]
int `??`(Local left, Local right) => left.value * 100 + right.value;

[[infix_operator]]
int `%%`(Local left, Local right) => left.value - right.value;

[[infix_operator]]
int `<=>`(Local left, Local right) => left.value - right.value;

void main() {
  Local one = Local{1};
  Local two = Local{2};

  if (!(one < two)) std::exit(1);
  if (!(one <= two)) std::exit(2);
  if (two < one) std::exit(3);
  if (two <= one) std::exit(4);
  if ((one ?? two) != 102) std::exit(5);
  if ((two %% one) != 1) std::exit(6);
  if ((one <=> two) != -1) std::exit(7);

  Measure small = Measure{3};
  Measure large = Measure{8};

  if (!(small < large)) std::exit(8);
  if (!(small <= large)) std::exit(9);
  if (large <= small) std::exit(10);
  if ((small ?? large) != 38) std::exit(11);
  if ((small <=> large) != -1) std::exit(12);

  Measure negated = negate small;
  if (negated.value != -3) std::exit(13);

  Measure doubledValue = small doubled;
  if (doubledValue.value != 6) std::exit(14);

  if ((3 combine 4) != 7) std::exit(15);
  if ((1 %% 2) != 12) std::exit(16);

  // Selective imports still bring every operator from the module.
  if (compare(small, large) != -1) std::exit(17);
}
