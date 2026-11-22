// Regression Test 81: Box<T> construction, adoption, and custom deleters.
//
// Verifies value-to-box conversion, explicit `Box<T>::from`, taking ownership
// of an existing pointer with a deleter, custom-deleter construction, and
// shared box copies invoking the deleter exactly once.
//
// Run:
//   gcli build tests\81_box_deleter.g --cpp -o build\test81.cpp
//   g++ -std=c++26 build\test81.cpp -o build\test81.exe
//   build\test81.exe

import std.memory.rc;
import std.lib;

struct Tracked {
  int value;
}

int release_count = 0;

void count_release(Tracked* item) {
  release_count = release_count + 1;
}

void adopt_stack_value() {
  Tracked tracked = Tracked{11};
  Box<Tracked> adopted = Box<Tracked>::adopt(&tracked, count_release);
  if (adopted.value != 11) std::exit(3);
}

void create_with_deleter() {
  Box<Tracked> created = Box<Tracked>::new(count_release);
  created.value = 5;
  if (created.value != 5) std::exit(5);
}

void copy_shared_box() {
  Tracked tracked = Tracked{3};
  Box<Tracked> first = Box<Tracked>::adopt(&tracked, count_release);
  Box<Tracked> second = first;
  if (second.value != 3) std::exit(7);
  if (first.value != 3) std::exit(8);
}

void main() {
  Box<int> converted = to_box(42);
  if (*converted != 42 || unwrap(converted) != 42) std::exit(1);

  Box<int> explicitBox = Box<int>::from(7);
  if (*explicitBox != 7) std::exit(2);

  Tracked original = Tracked{9};
  Box<Tracked> copied = to_box(original);
  if (copied.value != 9) std::exit(9);

  adopt_stack_value();
  if (release_count != 1) std::exit(4);

  create_with_deleter();
  if (release_count != 2) std::exit(6);

  copy_shared_box();
  if (release_count != 3) std::exit(10);

  if (!is_null(Box<Tracked>{})) std::exit(11);
}
