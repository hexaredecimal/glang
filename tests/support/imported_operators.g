// Support module for regression test 74.
//
// Declares an identifier-named prefix, postfix, and infix operator, plus
// shorthand functions whose parameters or return types are tuples.

[[prefix_operator]]
int increment(int value) => value + 1;

[[postfix_operator]]
int doubled(int value) => value * 2;

[[infix_operator]]
int average(int left, int right) => (left + right) / 2;

int sum_pair((int, int) pair) => pair.0 + pair.1;

(int, int) split(int value) => (value / 10, value % 10);
