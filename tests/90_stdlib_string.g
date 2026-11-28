// Regression Test 90: The SSO-capable String type and List<String>.
//
// Verifies inline/heap transitions, NUL termination, copy-on-write value
// semantics, string mixing, and pushing strings into a List<String>.
//
// Run:
//   build\gcli.exe build tests\90_stdlib_string.g --cpp -o build\test90.cpp
//   g++ -std=c++26 build\test90.cpp -o build\test90.exe
//   build\test90.exe

import std.string;
import std.container.list;
import std.lib;

void expect(bool condition, int code) {
  if (!condition) std::exit(code);
}

void main() {
  // Default construction behaves like an empty string.
  String empty;
  expect(empty.is_empty(), 1);
  expect(empty.size() == 0, 2);
  expect(empty.c_str()[0] == '\0', 3);
  empty.push('x');
  expect(empty.size() == 1 && empty.c_str()[0] == 'x', 4);
  empty.clear();
  expect(empty.is_empty() && empty.c_str()[0] == '\0', 5);

  // The 255/256 boundary covers the inline-to-heap transition and always
  // leaves room for the terminating NUL.
  String boundary = String::new();
  for (int index = 0; index < 255; ++index) {
    boundary.push('a');
  }
  expect(boundary.size() == 255, 6);
  expect(boundary.c_str()[254] == 'a', 7);
  expect(boundary.c_str()[255] == '\0', 8);
  boundary.push('b');
  expect(boundary.size() == 256, 9);
  expect(boundary.c_str()[255] == 'b', 10);
  expect(boundary.c_str()[256] == '\0', 11);

  // Copies share heap storage until one of them is mutated.
  String boundaryCopy = boundary;
  boundaryCopy.push('c');
  expect(boundary.size() == 256, 12);
  expect(boundaryCopy.size() == 257, 13);
  expect(boundary.c_str()[255] == 'b', 14);
  expect(boundaryCopy.c_str()[256] == 'c', 15);
  expect(boundaryCopy.c_str()[257] == '\0', 16);

  // Constructors, capacity, cloning, and clearing.
  String spaced = String::with_capacity(300);
  expect(spaced.size() == 0 && spaced.capacity >= 300, 17);
  spaced.push("hello");
  expect(spaced == "hello", 18);
  String cloned = spaced.clone();
  cloned.push('!');
  expect(cloned == "hello!", 19);
  expect(spaced == "hello", 20);
  spaced.clear();
  expect(spaced.is_empty(), 21);
  spaced.push("reused");
  expect(spaced == "reused", 22);

  // String mixing and content equality.
  String greeting = String::from("hello") + " " + String::from("world");
  expect(greeting == "hello world", 23);
  expect(greeting != "hello", 24);
  expect("hello world" == greeting, 25);
  String greetingCopy = greeting;
  expect(greetingCopy == greeting, 26);

  // Standard-library transforms return String values.
  const char* paddedSource = "  Mixed Case  ";
  String trimmed = paddedSource.trim();
  expect(trimmed == "Mixed Case", 27);
  expect(paddedSource == "  Mixed Case  ", 28);
  String upper = trimmed.to_upper();
  expect(upper == "MIXED CASE", 29);
  String lower = trimmed.to_lower();
  expect(lower == "mixed case", 30);
  String replaced = trimmed.replace_char(' ', '_');
  expect(replaced == "Mixed_Case", 31);
  expect(trimmed == "Mixed Case", 32);

  // Splitting produces a List<String>, and each segment is independently
  // owned.
  String csv = String::from("alpha,beta,gamma");
  auto parts = csv.split(',');
  expect(parts.length == 3, 33);
  expect(parts[0] == "alpha", 34);
  expect(parts[1] == "beta", 35);
  expect(parts[2] == "gamma", 36);
  parts[1].push('!');
  expect(parts[1] == "beta!", 37);
  expect(parts[0] == "alpha", 38);

  // List<String> push_back/push works for inline, empty, and heap strings.
  auto strings = List<String>::new();
  strings.push_back(String::from("one"));
  strings.push(String::from("two"));
  strings.push_back(String::new());
  String longString = String::new();
  for (int index = 0; index < 300; ++index) {
    longString.push('z');
  }
  strings.push_back(longString);
  expect(strings.length == 4, 39);
  expect(strings[0] == "one", 40);
  expect(strings[1] == "two", 41);
  expect(strings[2].is_empty(), 42);
  expect(strings[3] == longString, 43);
  expect(strings[3].size() == 300, 44);

  // Mutating an element must not mutate the local it was copied from.
  String longAlias = strings[3];
  strings[3].push('!');
  expect(strings[3].size() == 301, 45);
  expect(longAlias.size() == 300, 46);
  expect(longString.size() == 300, 47);
  expect(strings[3].c_str()[300] == '!', 48);
  expect(strings[3].c_str()[301] == '\0', 49);

  // Growth preserves earlier elements.
  for (int index = 0; index < 40; ++index) {
    strings.push_back(String::from("more"));
  }
  expect(strings.length == 44, 50);
  expect(strings[0] == "one" && strings[1] == "two", 51);
  expect(strings[3].size() == 301, 52);
  expect(strings[43] == "more", 53);
}
