import std.prelude;

struct std::slice {}

[[private, extern]]
T[] __slice_from_ptr<T>(T* pointer, int count);

/// Build a non-owning `T[]` view over `count` values starting at `pointer`.
T[] std::slice::from_ptr<T>(T* pointer, int count) =>
    __slice_from_ptr(pointer, count);

/// The raw pointer at the start of a slice. The slice must not be empty.
T* std::slice::to_pointer<T>(T[] arr) => &arr[0];

T[] from_ptr<T>(T* pointer, int count) => std::slice::from_ptr(pointer, count);
T* to_pointer<T>(T[] arr) => std::slice::to_pointer(arr);
