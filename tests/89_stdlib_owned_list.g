// Regression Test 89: Owned<T>, the Glang List<T>, and string ownership.
//
// Verifies that List<T> is an ordinary Glang dynamic array backed by
// std::memory::rc, that it supports ranges and algorithms, and that string
// duplication is centered on std::string::own.
//
// Run:
//   build\gcli.exe build tests\89_stdlib_owned_list.g --cpp -o build\test89.cpp
//   g++ -std=c++26 build\test89.cpp -o build\test89.exe
//   build\test89.exe

import std.container.list;
import std.container.sequence;
import std.algo.range;
import std.algo.sort;
import std.memory.owned;
import std.memory.rc;
import std.string.owned;
import std.string.dup;
import std.string.clone;
import std.string.trim;
import std.string.transform;
import std.string.replace;
import std.string.split;
import std.string.compare;
import std.string.builder;
import std.lib;

int double_it(int value) => value * 2;

bool is_even(int value) => value % 2 == 0;

int pointer_first(int* values) => values[0];

struct PointerHolder {
  int* values;
}

void expect(bool condition, int code) {
  if (!condition) std::exit(code);
}

void main() {
  // Owned<T> allocation, cloning, resizing, and release.
  auto owned = std::memory::alloc<int>(4).unwrap();
  expect(owned.count == 4, 1);
  owned.ptr[0] = 1;
  owned.ptr[1] = 2;
  owned.ptr[2] = 3;
  owned.ptr[3] = 4;
  expect(owned.get()[2] == 3, 2);
  expect(owned.get_count() == 4, 3);

  auto ownedCopy = owned.clone().unwrap();
  expect(ownedCopy.ptr[3] == 4, 4);
  expect(ownedCopy.resize(6), 5);
  expect(ownedCopy.count == 6 && owned.count == 4, 6);
  ownedCopy.release();
  expect(ownedCopy.ptr == nullptr && ownedCopy.count == 0, 7);
  owned.release();
  expect(owned.is_null(), 8);

  auto taken = std::memory::alloc_value<int>(7).unwrap();
  int* raw = taken.take();
  expect(raw != nullptr && *raw == 7, 9);
  std::memory::free_raw(raw);

  // List<T> is a normal generic struct with a Box-backed buffer.
  auto list = List<int>::new();
  expect(list.length == 0 && list.is_empty() && list.size() == 0, 10);
  list.push(10);
  list.push(20);
  list.push_back(30);
  expect(list.length == 3 && list.size() == 3, 11);
  expect(list[0] == 10 && list[2] == 30, 12);
  expect(*list.at(1) == 20, 13);
  expect(*list.front() == 10 && *list.back() == 30, 14);

  List<int> reserved = List<int>::with_capacity(8);
  reserved.push(1);
  expect(reserved.capacity == 8 && reserved.length == 1, 15);
  reserved.release();
  expect(reserved.capacity == 0 && reserved.length == 0, 16);

  // A copy shares the handle, so clone is required for independent storage.
  auto copied = list.clone();
  copied[0] = 99;
  expect(list[0] == 10 && copied[0] == 99, 17);

  // Slices view the live buffer.
  int[] slice = list.as_slice();
  expect(slice.length == 3 && slice[1] == 20, 18);

  auto (popped, hadValue) = list.pop();
  expect(hadValue && popped == 30 && list.length == 2, 19);
  auto (missing, empty) = list.pop();
  expect(empty && missing == 20 && list.length == 1, 20);
  list.push(30);
  list.push(40);
  expect(list.length == 3, 21);

  // clear keeps capacity; release drops the buffer.
  auto scratch = List<int>::with_capacity(4);
  scratch.push(1);
  scratch.clear();
  expect(scratch.length == 0 && scratch.capacity == 4, 22);
  scratch.release();
  expect(scratch.capacity == 0, 23);

  // Arrays convert into lists.
  auto fromArray = [4, 5, 6].to_list();
  expect(fromArray.length == 3 && fromArray[0] == 4, 24);
  expect(fromArray.contains(5) && fromArray.index_of(6) == 2, 25);
  expect(fromArray.index_of(9) == -1, 26);

  // Algorithms copy before mutating.
  auto source = [3, 1, 2].to_list();
  auto mapped = std::algorithm::map(source, double_it);
  expect(source[0] == 3 && mapped[0] == 6, 27);
  auto sorted = std::algorithm::to_sorted(source);
  expect(source[0] == 3 && sorted[0] == 1 && sorted[2] == 3, 28);
  auto filtered = std::algorithm::filter(source, is_even);
  expect(filtered.length == 1 && filtered[0] == 2, 29);

  // Lazy sequences round-trip through List<T>.
  auto collected = range(1, 5).to_list();
  expect(collected.length == 4 && collected[0] == 1 && collected[3] == 4, 30);
  auto roundTrip = [7, 8, 9].to_list().to_lazy().to_list();
  expect(roundTrip.length == 3 && roundTrip[2] == 9, 31);
  expect(roundTrip.clone().contains(8), 32);

  // String ownership is centered on the SSO-capable String type.
  auto ownedText = std::string::own("hello").unwrap();
  expect(ownedText.c_str()[0] == 'h', 33);
  auto alias = ownedText;
  expect(alias.c_str()[4] == 'o', 34);
  auto duplicate = std::string::dup("world").unwrap();
  expect(duplicate.c_str()[4] == 'd', 35);
  auto stringCopy = std::string::clone("copy");
  expect(stringCopy.c_str()[3] == 'y', 36);
  expect(!alias.is_empty(), 37);

  // String transforms allocate a result and leave the input untouched.
  const char* rawText = "  Hello  ";
  auto trimmed = rawText.trim();
  expect(trimmed == "Hello", 38);
  expect(compare_strings(rawText, "  Hello  ") == 0, 39);
  auto upper = "abc".to_upper();
  expect(upper == "ABC", 40);
  auto lower = "ABC".to_lower();
  expect(lower == "abc", 41);
  auto replaced = "banana".replace_char('a', 'o');
  expect(replaced == "bonono", 42);
  auto segments = "a,b,c".split(',');
  expect(segments.length == 3, 43);
  expect(segments[1] == "b", 44);
  auto joined = join(segments, "-");
  expect(compare_strings(joined.to_string(), "a-b-c") == 0, 45);

  // List<String> accepts both inline and heap-backed strings, and mutations
  // detach copy-on-write storage instead of changing other copies.
  auto strings = List<String>::new();
  strings.push_back(String::from("alpha"));
  strings.push(String::from("beta"));
  String heapText = String::from("01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789");
  strings.push_back(heapText);
  expect(strings.length == 3, 50);
  expect(strings[0] == "alpha" && strings[1] == "beta", 51);
  expect(strings[2] == heapText, 52);
  String heapAlias = strings[2];
  strings[2].push('!');
  expect(strings[2].size() == 291, 53);
  expect(heapAlias.size() == 290, 54);
  expect(heapText.size() == 290, 55);
  expect(strings[0] == "alpha", 56);

  // Fixed arrays and slices decay to element pointers, like C.
  int[4] decaySource = [1, 2, 3, 4];
  int* decayPointer = decaySource;
  expect(decayPointer[2] == 3, 46);
  int[] decaySlice = decaySource;
  int* slicePointer = decaySlice;
  expect(slicePointer[3] == 4, 47);
  expect(pointer_first(decaySource) == 1, 48);
  PointerHolder holder = PointerHolder{decaySource};
  expect(holder.values[1] == 2, 49);
}

