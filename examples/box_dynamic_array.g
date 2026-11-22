// A C-style dynamic array whose backing block is owned by Box<T>.
//
// In C you would keep `T* data`, `size_t length`, and `size_t capacity`, call
// malloc/realloc while growing, and remember to free the block yourself.
// Here the block lives behind Box<T>, which the backend maps to
// std::shared_ptr<T>. Assigning a new block into the Box releases the old one
// through the `free` deleter, and leaving scope releases the final block, so
// the example never calls free() directly.
//
// Box<T> is a single-object shared_ptr<T> (not shared_ptr<T[]>), so the array
// is represented exactly like the C version: a pointer to the first element
// plus a length and capacity. `box_array_data` recovers the non-owning raw
// pointer with `&*storage`.
//
// Build and run:
//   gcli build examples\box_dynamic_array.g --cpp -o build\box_array.cpp
//   g++ -std=c++26 build\box_array.cpp -o build\box_array.exe
//   build\box_array.exe

import std.memory.rc;
import std.memory.c.alloc;
import std.io.print;

struct BoxArray<T> {
  /// Owns the malloc'ed block. The deleter is `free`.
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

/// Non-owning view of the block. `storage` is a shared_ptr<T>, so `*storage`
/// is the first element and `&*storage` is the element pointer.
T* box_array_data<T>(Box<T> storage) => &(*storage);

/// Grow the block to hold at least `requested` elements. No explicit free is
/// needed: assigning into `array.storage` drops the old shared_ptr, which runs
/// the stored `free` deleter.
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

  // Copy the old elements before the old owner is released.
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

/// Remove and return the last element. The flag is false when empty.
(T, bool) box_array_pop<T>(BoxArray<T>* array) {
  if (array == nullptr || array.length == 0) {
    T missing;
    return (missing, false);
  }
  array.length = array.length - 1;
  return (box_array_data(array.storage)[array.length], true);
}

/// Read an element. The flag is false when the index is out of bounds.
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

/// Release the block early. Dropping the BoxArray does the same thing at scope
/// exit, so this is only needed when memory should be returned sooner.
void box_array_clear<T>(BoxArray<T>* array) {
  if (array == nullptr) {
    return;
  }
  array.storage = nullptr;
  array.length = 0;
  array.capacity = 0;
}

int main() {
  BoxArray<int> squares = make_box_array<int>();

  for (int value = 1; value <= 10; value = value + 1) {
    if (!box_array_push(&squares, value * value)) {
      printf("allocation failed\n");
      return 1;
    }
  }

  printf("length=%d capacity=%d\n", squares.length as int,
         squares.capacity as int);
  printf("values:");
  for (ulong index = 0; index < squares.length; index = index + 1) {
    auto (value, found) = box_array_get(&squares, index);
    if (!found) {
      return 2;
    }
    printf(" %d", value);
  }
  printf("\n");

  if (!box_array_set(&squares, 0, 42)) {
    return 3;
  }
  auto (first, firstFound) = box_array_get(&squares, 0);
  if (!firstFound || first != 42) {
    return 4;
  }
  auto (missing, missingFound) = box_array_get(&squares, squares.length);
  if (missingFound) {
    return 5;
  }

  auto (last, lastFound) = box_array_pop(&squares);
  if (!lastFound || last != 100) {
    return 6;
  }
  printf("popped=%d remaining=%d\n", last, squares.length as int);

  // Early release demonstration. `temporary` is a Box too.
  BoxArray<int> temporary = make_box_array<int>();
  if (!box_array_push(&temporary, 7)) {
    return 7;
  }
  box_array_clear(&temporary);
  if (!is_null(temporary.storage) || temporary.length != 0 ||
      temporary.capacity != 0) {
    return 8;
  }

  // `squares` is not freed here. Its Box releases the block when main exits.
  return 0;
}
