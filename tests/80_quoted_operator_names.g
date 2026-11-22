// Regression Test 80: Backtick-quoted operator declarations.
//
// Symbol-named operators quote the symbol in their declaration: `*`, `+`,
// `%`, `@`. Uses stay bare. This keeps an operator named `*` separate from a
// pointer return type such as `const char*` or `int*`.
//
// Run:
//   gcli build tests\80_quoted_operator_names.g --cpp -o build\test80.cpp
//   g++ -std=c++26 build\test80.cpp -o build\test80.exe
//   build\test80.exe

import std.lib;

struct Node {
  int value;
}

// Pointer return type followed by the backticked `*` operator name.
[[infix_operator]]
const char* `*` (const char* left, const char* right) => left;

// Pointer return type and pointer parameters.
[[infix_operator]]
int* `+` (int* left, int* right) => left;

[[infix_operator]]
int `%` (Node left, Node right) => left.value - right.value;

[[prefix_operator]]
Node* `@` (Node* node) => node;

int* pointer_identity(int* value) => value;

void main() {
  const char* picked = "alpha" * "beta";
  if (picked[0] != 'a') std::exit(1);

  int first = 3;
  int second = 4;
  int* chosen = &first + &second;
  if (*chosen != first) std::exit(2);

  Node low = Node{2};
  Node high = Node{9};
  if ((high % low) != 7) std::exit(3);

  Node* node = @(&high);
  if (node.value != 9) std::exit(4);

  int* pointer = pointer_identity(&second);
  if (*pointer != second) std::exit(5);
}
