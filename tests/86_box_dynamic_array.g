// Regression Test 86: C-style dynamic array managed by Box<T>.
//
// The backing block is allocated with malloc (via std::memory::allocate) and
// adopted by Box<T>, which is std::shared_ptr<T>. Growth assigns a new block
// into the Box, releasing the old one with the `free` deleter. No test code
// calls free directly.
//
// Run:
//   gcli build tests\86_box_dynamic_array.g --cpp -o build\test86.cpp
//   g++ -std=c++26 build\test86.cpp -o build\test86.exe
//   build\test86.exe

import std.memory.rc;
import std.memory.c.alloc;
import std.lib;

struct BoxArray<T> {
  Box<T> storage;
  ulong length;
  ulong capacity;
}

BoxArray<T> make_box_array<T>() {
  BoxArray<T> result;
  result.length = 0;
  result.capacity = 0;
  return result;
}

T* box_array_data<T>(Box<T> storage) => &(*storage);

bool box_array_reserve<T>(BoxArray<T>* array, ulong requested) {
  if (array == nullptr) {
    return false;
  }
  if (requested <= array.capacity) {
    return true;
  }

  ulong newCapacity = array.capacity;
  if (newCapacity == 0) {
    newCapacity = 4;
  }
  while (newCapacity < requested) {
    newCapacity = newCapacity * 2;
  }

  auto (buffer, allocated) = std::memory::allocate<T>(newCapacity);
  if (!allocated) {
    return false;
  }

  if (array.length > 0) {
    T* oldData = box_array_data(array.storage);
    for (ulong index = 0; index < array.length; index = index + 1) {
      buffer[index] = oldData[index];
    }
  }

  array.storage = Box<T>::adopt(buffer, free);
  array.capacity = newCapacity;
  return true;
}

bool box_array_push<T>(BoxArray<T>* array, T value) {
  if (array == nullptr) {
    return false;
  }
  if (array.length == array.capacity) {
    if (!box_array_reserve(array, array.length + 1)) {
      return false;
    }
  }
  box_array_data(array.storage)[array.length] = value;
  array.length = array.length + 1;
  return true;
}

(T, bool) box_array_pop<T>(BoxArray<T>* array) {
  if (array == nullptr || array.length == 0) {
    T missing;
    return (missing, false);
  }
  array.length = array.length - 1;
  return (box_array_data(array.storage)[array.length], true);
}

(T, bool) box_array_get<T>(BoxArray<T>* array, ulong index) {
  if (array == nullptr || index >= array.length) {
    T missing;
    return (missing, false);
  }
  return (box_array_data(array.storage)[index], true);
}

bool box_array_set<T>(BoxArray<T>* array, ulong index, T value) {
  if (array == nullptr || index >= array.length) {
    return false;
  }
  box_array_data(array.storage)[index] = value;
  return true;
}

void box_array_clear<T>(BoxArray<T>* array) {
  if (array == nullptr) {
    return;
  }
  array.storage = nullptr;
  array.length = 0;
  array.capacity = 0;
}

void main() {
  BoxArray<int> values = make_box_array<int>();
  if (!is_null(values.storage) || values.length != 0 ||
      values.capacity != 0) {
    std::exit(1);
  }

  // Force several reallocations and copies.
  for (int value = 1; value <= 1000; value = value + 1) {
    if (!box_array_push(&values, value)) std::exit(2);
  }
  if (values.length != 1000) std::exit(3);
  if (values.capacity != 1024) std::exit(4);

  auto (first, firstOk) = box_array_get(&values, 0);
  if (!firstOk || first != 1) std::exit(5);
  auto (last, lastOk) = box_array_get(&values, values.length - 1);
  if (!lastOk || last != 1000) std::exit(6);
  auto (missing, missingOk) = box_array_get(&values, values.length);
  if (missingOk) std::exit(7);

  if (!box_array_set(&values, 10, 42)) std::exit(8);
  auto (changed, changedOk) = box_array_get(&values, 10);
  if (!changedOk || changed != 42) std::exit(9);
  if (box_array_set(&values, values.length, 1)) std::exit(10);

  auto (popped, poppedOk) = box_array_pop(&values);
  if (!poppedOk || popped != 1000 || values.length != 999) std::exit(11);
  if (!box_array_push(&values, 2000)) std::exit(12);
  auto (reused, reusedOk) = box_array_get(&values, 999);
  if (!reusedOk || reused != 2000) std::exit(13);

  // Drain the array through the Box-managed block.
  while (values.length > 0) {
    auto (value, found) = box_array_pop(&values);
    if (!found) std::exit(14);
  }
  auto (emptyValue, emptyOk) = box_array_pop(&values);
  if (emptyOk) std::exit(15);

  // Clear releases the block immediately and resets the array.
  if (!box_array_push(&values, 5)) std::exit(16);
  box_array_clear(&values);
  if (!is_null(values.storage) || values.length != 0 ||
      values.capacity != 0) {
    std::exit(17);
  }

  // A scoped array is released by Box when main exits.
  BoxArray<int> scoped = make_box_array<int>();
  if (!box_array_push(&scoped, 11)) std::exit(18);
  auto (scopedValue, scopedOk) = box_array_get(&scoped, 0);
  if (!scopedOk || scopedValue != 11) std::exit(19);
}
