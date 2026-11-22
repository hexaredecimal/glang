// Regression Test 73: Lazy sequences and ranges.
//
// Verifies that `Lazy<T>` sources and combinators defer work until a
// terminal operation consumes them, and that arrays, fixed arrays,
// slices, List<T>, strings, and integer ranges all participate.
//
// Run:
//   gcli build tests\73_lazy_sequences.g --cpp -o build\test73.cpp
//   g++ -std=c++26 build\test73.cpp -o build\test73.exe
//   build\test73.exe

import std.container.list;
import std.container.sequence;
import std.container.pair;
import std.lib;

[[infix_operator]]
T `|>` <T>(T value, T (*fn)(T)) => fn(value);

int evaluations = 0;

int counted(int value) {
  evaluations = evaluations + 1;
  return value * 10;
}

bool is_even(int value) => value % 2 == 0;

void record(int value) {
  evaluations = evaluations + value;
}

void expect(bool condition, int code) {
  if (!condition) std::exit(code);
}

void main() {
  // Mapping is deferred until consumption.
  evaluations = 0;
  auto doubled = [1, 2, 3, 4, 5]
      .to_lazy()
      |> map() { int value -> counted(value); };
  expect(evaluations == 0, 1);

  auto first_two = doubled |> take(2) |> to_list();
  expect(evaluations == 2, 2);
  expect(first_two.length == 2, 3);
  expect(first_two[0] == 10 && first_two[1] == 20, 4);

  // Copies of a lazy sequence share progression state.
  auto remainder = doubled |> to_list();
  expect(evaluations == 5, 5);
  expect(remainder.length == 3 && remainder[2] == 50, 6);

  // Range, filter, and fold.
  auto filtered_total = range(0, 10)
      |> filter() { int value -> is_even(value); }
      |> fold(0) { int acc, int value -> acc + value; };
  expect(filtered_total == 20, 7);

  // Basic terminals.
  auto reduced = range(1, 5) |> reduce() { int a, int b -> a + b; };
  expect(reduced == 10, 8);
  expect((range(0, 7) |> count()) == 7, 9);
  auto evens = range(0, 7) |> count_if() { int value -> is_even(value); };
  expect(evens == 4, 10);
  expect((range(1, 5) |> sum()) == 10, 11);

  // any / all short-circuit.
  evaluations = 0;
  auto has_two = range(0, 100)
      |> map() { int value -> counted(value); }
      |> any() { int value -> value == 20; };
  expect(has_two, 12);
  expect(evaluations == 3, 13);

  auto all_small = range(1, 4) |> all() { int value -> value < 4; };
  expect(all_small, 14);

  // drop / take_while / drop_while / stride.
  auto dropped = range(0, 6) |> drop(2) |> to_list();
  expect(dropped.length == 4 && dropped[0] == 2, 15);

  auto taken = range(0, 100)
      |> take_while() { int value -> value < 3; }
      |> to_list();
  expect(taken.length == 3 && taken[2] == 2, 16);

  auto skipped = range(0, 6)
      |> drop_while() { int value -> value < 3; }
      |> to_list();
  expect(skipped.length == 3 && skipped[0] == 3, 17);

  auto stepped = range(0, 10) |> stride(3) |> to_list();
  expect(stepped.length == 4, 18);
  expect(stepped[0] == 0 && stepped[1] == 3 && stepped[3] == 9, 19);

  // Strings yield their bytes.
  auto chars = "abc".to_lazy() |> to_list();
  expect(chars.length == 3, 20);
  expect(chars[0] == 'a' && chars[2] == 'c', 21);

  // List<T> sources.
  auto list = to_list([4, 5, 6]);
  expect((list.to_lazy() |> sum()) == 15, 22);

  // Slice sources.
  int[5] raw = [0, 1, 2, 3, 4];
  int[] slice = raw[1..4];
  auto slice_values = slice.to_lazy() |> to_list();
  expect(slice_values.length == 3, 23);
  expect(slice_values[0] == 1 && slice_values[2] == 3, 24);

  // Fixed arrays are accepted directly.
  expect((raw.to_lazy() |> count()) == 5, 25);

  // enumerate / zip / chain.
  auto indexed = [7, 8].to_lazy() |> enumerate() |> to_list();
  expect(indexed.length == 2, 26);
  expect(indexed[0].0 == 0 && indexed[1].0 == 1 && indexed[1].1 == 8, 27);

  auto zipped = range(0, 3) |> zip(range(10, 13)) |> to_list();
  expect(zipped.length == 3, 28);
  expect(zipped[0].0 == 0 && zipped[0].1 == 10, 29);
  expect(zipped[2].0 == 2 && zipped[2].1 == 12, 30);

  auto chained = range(0, 2) |> chain(range(10, 12)) |> to_list();
  expect(chained.length == 4, 31);
  expect(chained[2] == 10 && chained[3] == 11, 32);

  // flat_map with a Lazy-returning callback.
  auto flattened = range(1, 4)
      |> flat_map() { int value -> range(0, value); }
      |> to_list();
  expect(flattened.length == 6, 33);
  expect(flattened[0] == 0 && flattened[1] == 0 && flattened[2] == 1, 34);
  expect(flattened[3] == 0 && flattened[4] == 1 && flattened[5] == 2, 35);

  // first / first_or / last_or / nth.
  auto first_value = range(5, 8) |> first_or(-1);
  expect(first_value == 5, 36);

  auto last_value = range(5, 8) |> last_or(-1);
  expect(last_value == 7, 37);

  auto nth_value = range(5, 8) |> nth(1);
  expect(nth_value.1 && nth_value.0 == 6, 38);

  auto none = range(0, 0) |> first_or(42);
  expect(none == 42, 39);

  // inspect observes values without changing them.
  evaluations = 0;
  auto inspected = range(1, 4)
      |> inspect(record)
      |> to_list();
  expect(inspected.length == 3 && evaluations == 6, 40);

  // for_each is terminal.
  evaluations = 0;
  range(1, 4).to_lazy() |> for_each(record);
  expect(evaluations == 6, 41);

  // Descending and stepped ranges.
  auto descending = range(3, 0, -1) |> to_list();
  expect(descending.length == 3 && descending[0] == 3 && descending[2] == 1, 42);

  // Laziness survives many chained stages without materializing.
  evaluations = 0;
  auto deep = range(0, 1000000)
      |> map() { int value -> counted(value); }
      |> filter() { int value -> value >= 0; }
      |> take(3)
      |> to_list();
  expect(deep.length == 3 && evaluations == 3, 43);

  auto collected = range(0, 3) |> collect();
  expect(collected.length == 3 && collected[2] == 2, 44);

  auto first_pair = range(5, 8) |> first();
  expect(first_pair.1 && first_pair.0 == 5, 45);

  expect((range(2, 2) |> count()) == 0, 46);
}
