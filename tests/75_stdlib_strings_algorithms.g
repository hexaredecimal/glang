// Regression Test 75: Expanded string and algorithm utilities.
//
// Exercises std.string.trim, std.string.count, std.string.replace,
// std.string.compare, std.string.parse, std.algo.search, and
// std.algo.aggregate.
//
// Run:
//   gcli build tests\75_stdlib_strings_algorithms.g --cpp -o build\test75.cpp
//   g++ -std=c++26 build\test75.cpp -o build\test75.exe
//   build\test75.exe

import std.string.trim;
import std.string.count;
import std.string.replace;
import std.string.compare;
import std.string.parse;
import std.string.owned;
import std.algo.search;
import std.algo.aggregate;
import std.lib;

bool is_even(int value) => value % 2 == 0;

void main() {
  const char* paddedSource = "  hello  ";
  auto padded = trim(paddedSource);
  if (compare_strings(padded.c_str(), "hello") != 0) std::exit(1);
  if (compare_strings(paddedSource, "  hello  ") != 0) std::exit(2);

  auto dotted = trim_right("x.txt..", '.');
  if (compare_strings(dotted.c_str(), "x.txt") != 0) std::exit(3);

  if (count_char(padded.c_str(), 'l') != 2) std::exit(4);
  if (count_substring(padded.c_str(), "ll") != 1) std::exit(5);
  if (count_substring(padded.c_str(), "hello!") != 0) std::exit(6);

  const char* replaceSource = "hello";
  auto replaced = replace_char(replaceSource, 'l', 'L');
  if (compare_strings(replaced.c_str(), "heLLo") != 0) std::exit(7);
  if (compare_strings(replaceSource, "hello") != 0) std::exit(8);

  if (!equals_ignore_case("Glang", "gLaNg")) std::exit(9);
  if (compare_ignore_case("abc", "ABD") != -1) std::exit(10);
  if (compare_strings("abc", "abd") != -1) std::exit(11);
  if (!is_empty_string("") || is_empty_string("x")) std::exit(12);
  if (!is_blank(" \t\n")) std::exit(13);

  if (!is_integer("-42") || is_integer("4x") || is_unsigned_integer("-1")) {
    std::exit(14);
  }
  auto (parsedInt, intOk) = parse_int("-42");
  if (!intOk || parsedInt != -42) std::exit(15);
  auto (parsedLong, longOk) = parse_long("123456");
  if (!longOk || parsedLong != 123456) std::exit(16);
  if (!is_decimal("-.5") || !is_decimal("5.") || is_decimal("..")) {
    std::exit(17);
  }
  auto (parsedDouble, doubleOk) = parse_double("2.5");
  if (!doubleOk || parsedDouble != 2.5) std::exit(18);
  auto (badInt, badIntOk) = parse_int("nope");
  if (badIntOk || badInt != 0) std::exit(19);

  int[6] numbers = [3, 1, 4, 1, 5, 9];
  int[5] sorted = [1, 2, 3, 4, 5];

  if (find_index(numbers, 1) != 1) std::exit(20);
  if (find_last_index(numbers, 1) != 3) std::exit(21);
  if (find_index(numbers, 7) != -1) std::exit(22);
  if (find_index_if(numbers, is_even) != 2) std::exit(23);
  if (find_last_index_if(numbers, is_even) != 2) std::exit(24);
  auto (firstEven, foundEven) = find_first(numbers, is_even);
  if (!foundEven || firstEven != 4) std::exit(25);

  if (binary_search(sorted, 4) != 3) std::exit(26);
  if (binary_search(sorted, 6) != -1) std::exit(27);
  if (lower_bound(sorted, 3) != 2) std::exit(28);
  if (upper_bound(sorted, 3) != 3) std::exit(29);

  auto (smallest, hasSmallest) = min_element(numbers);
  auto (largest, hasLargest) = max_element(numbers);
  if (!hasSmallest || smallest != 1) std::exit(30);
  if (!hasLargest || largest != 9) std::exit(31);
  if (sum(numbers) != 23) std::exit(32);
  if (product(numbers) != 540) std::exit(33);
  if (count_value(numbers, 1) != 2) std::exit(34);
  if (is_sorted(numbers) || !is_sorted(sorted)) std::exit(35);
  if (all_equal(sorted)) std::exit(36);

  int[3] blanks = [0, 0, 0];
  fill(blanks, 7);
  if (!all_equal(blanks) || blanks[2] != 7) std::exit(37);
}

