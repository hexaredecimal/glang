import std.prelude;
import std.panic;
import std.result;
import std.memory.rc;
import std.memory.c.alloc;
import std.memory.c.mem;
import std.container.slice;

struct std::list {} // Module struct kept for std.container.list compatibility

/// A growable, contiguous dynamic array.
///
/// The backing block is held by `Box<T>` (`std::memory::rc`), so the memory is
/// returned to the allocator automatically when the last reference to the
/// block is dropped. Copying a `List<T>` copies the handle and shares the
/// elements; use `clone` for a deep copy.
struct List<T> {
    Box<T> storage;
    int length;
    int capacity;
}

/// Create an empty list.
List<T> List<T>::new() => List<T>{};

/// Create an empty list with room for `capacity` elements.
List<T> List<T>::with_capacity(int capacity) {
    List<T> result;
    if (capacity <= 0) {
        return result;
    }
    result.storage = Box<T>::array(capacity as ulong);
    result.capacity = capacity;
    return result;
}

/// Adopt a raw buffer produced by `std::memory::allocate` or an intrinsic.
/// The list releases the buffer with `free` when the last copy is dropped.
List<T> List<T>::from_buffer(T* buffer, int count) {
    List<T> result;
    if (buffer == nullptr || count <= 0) {
        std::memory::free_raw(buffer);
        return result;
    }
    result.storage = Box<T>::adopt(buffer, free);
    result.length = count;
    result.capacity = count;
    return result;
}

/// The first element of the backing block. Null when the list is empty.
T* std::list::data<T>(List<T>* self) {
    if (self.storage == nullptr) {
        return nullptr;
    }
    return &(*self.storage);
}

/// Ensure the list can hold at least `capacity` elements without reallocating.
/// Existing elements are preserved.
void std::list::reserve<T>(List<T>* self, int capacity) {
    if (capacity <= self.capacity) {
        return;
    }
    int next = self.capacity;
    if (next < 8) {
        next = 8;
    }
    while (next < capacity) {
        next = next * 2;
    }
    Box<T> nextStorage = Box<T>::array(next as ulong);
    T* source = std::list::data(self);
    T* destination = &(*nextStorage);
    for (int index = 0; index < self.length; index = index + 1) {
        destination[index] = source[index];
    }
    self.storage = nextStorage;
    self.capacity = next;
}

/// Append `value`. The list grows as needed.
void std::list::push<T>(List<T>* self, T value) {
    if (self.length == self.capacity) {
        int next = 8;
        if (self.capacity > 0) {
            next = self.capacity * 2;
        }
        std::list::reserve(self, next);
    }
    T* buffer = std::list::data(self);
    buffer[self.length] = value;
    self.length = self.length + 1;
}

/// Append `value`. Alias for `push`.
void std::list::push_back<T>(List<T>* self, T value) => std::list::push(self, value);

/// Remove and return the last element. The flag is false when empty.
(T, bool) std::list::pop<T>(List<T>* self) {
    if (self.length == 0) {
        T empty;
        return (empty, false);
    }
    self.length = self.length - 1;
    T* buffer = std::list::data(self);
    T value = buffer[self.length];
    T empty;
    buffer[self.length] = empty;
    return (value, true);
}

/// Pointer to the element at `index`. Panics when the index is out of range.
T* std::list::at<T>(List<T>* self, int index) {
    if (index < 0 || index >= self.length) {
        std::panic("std::list::at: Index out of range");
    }
    T* buffer = std::list::data(self);
    return &buffer[index];
}

/// Remove every element while keeping the allocated capacity.
void std::list::clear<T>(List<T>* self) {
    T* buffer = std::list::data(self);
    for (int index = 0; index < self.length; index = index + 1) {
        T empty;
        buffer[index] = empty;
    }
    self.length = 0;
}

/// Drop this list's reference to the backing block and reset the list.
/// The block is freed automatically when the last reference is dropped.
void std::list::release<T>(List<T>* self) {
    self.storage = nullptr;
    self.length = 0;
    self.capacity = 0;
}

/// Number of elements in the list.
int std::list::size<T>(List<T>* self) => self.length;

/// True when the list contains no elements.
bool std::list::is_empty<T>(List<T>* self) => self.length == 0;

/// The elements as a non-owning view. The view is invalidated by growth,
/// release, or any operation that reallocates the backing block.
T[] std::list::as_slice<T>(List<T>* self) =>
    std::slice::from_ptr(std::list::data(self), self.length);

/// Deep-copy the list into a freshly allocated block.
List<T> std::list::clone<T>(List<T> source) {
    List<T> result = List<T>::with_capacity(source.length);
    T* destination = std::list::data(&result);
    T* origin = std::list::data(&source);
    for (int index = 0; index < source.length; index = index + 1) {
        destination[index] = origin[index];
    }
    result.length = source.length;
    return result;
}

List<T> std::to_list<T>(T[] elements) => to_list(elements);

/// Copy an array or slice into a new list.
List<T> to_list<T>(T[] elements) {
    auto result = List<T>::with_capacity(elements.length);
    for (int i = 0; i < elements.length; ++i) {
        result.push_back(elements[i]);
    }
    return result;
}

/// Deep-copy a list.
List<T> to_list<T>(List<T> elements) => elements.clone();

void for_each<T>(List<T> list, void (*fn)(T)) {
    for (int i = 0; i < list.length; ++i) {
        fn(list[i]);
    }
}

bool contains<T>(List<T> list, T item) {
    for (int i = 0; i < list.length; ++i) {
        if (list[i] == item) {
            return true;
        }
    }
    return false;
}

int index_of<T>(List<T> list, T item) {
    for (int i = 0; i < list.length; ++i) {
        if (list[i] == item) {
            return i;
        }
    }
    return -1;
}

T* front<T>(List<T> list) {
    if (list.length == 0) {
        std::panic("Attempt to access front of an empty list");
    }
    T* buffer = std::list::data(&list);
    return &buffer[0];
}

T* back<T>(List<T> list) {
    if (list.length == 0) {
        std::panic("Attempt to access back of an empty list");
    }
    T* buffer = std::list::data(&list);
    return &buffer[list.length - 1];
}

// Free-function forms keep every operation usable through UFCS.

void reserve<T>(List<T>* self, int capacity) => std::list::reserve(self, capacity);
T* data<T>(List<T>* self) => std::list::data(self);
void push<T>(List<T>* self, T value) => std::list::push(self, value);
void push_back<T>(List<T>* self, T value) => std::list::push_back(self, value);
(T, bool) pop<T>(List<T>* self) => std::list::pop(self);
T* at<T>(List<T>* self, int index) => std::list::at(self, index);
void clear<T>(List<T>* self) => std::list::clear(self);
void release<T>(List<T>* self) => std::list::release(self);
int size<T>(List<T>* self) => std::list::size(self);
bool is_empty<T>(List<T>* self) => std::list::is_empty(self);
T[] as_slice<T>(List<T>* self) => std::list::as_slice(self);
List<T> clone<T>(List<T> source) => std::list::clone(source);
