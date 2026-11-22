// Support module for regression test 77.
//
// Declares identifier-named and symbol-named prefix, infix, and postfix
// operators using `<`, `<=`, `??`, `%`, and `<=>`.

struct Measure {
  int value;
}

[[prefix_operator]]
Measure negate(Measure value) => Measure{-value.value};

[[postfix_operator]]
Measure doubled(Measure value) => Measure{value.value * 2};

[[infix_operator]]
bool `<`(Measure left, Measure right) => left.value < right.value;

[[infix_operator]]
bool `<=`(Measure left, Measure right) => left.value <= right.value;

[[infix_operator]]
int `??`(Measure left, Measure right) => left.value * 10 + right.value;

[[infix_operator]]
int compare(Measure left, Measure right) {
  if (left.value < right.value) {
    return -1;
  }
  if (left.value > right.value) {
    return 1;
  }
  return 0;
}

[[infix_operator]]
int `<=>`(Measure left, Measure right) => compare(left, right);

[[infix_operator]]
int combine(int left, int right) => left + right;

[[infix_operator]]
int `%%` (int left, int right) => left * 10 + right;
