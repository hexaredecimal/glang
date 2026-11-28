import std.memory.prelude;

[[extern, c_abi]]
void* malloc(size_t size);

[[extern, c_abi]]
void* calloc(size_t count, size_t size);

[[extern, c_abi]]
void* realloc(void* pointer, size_t size);

[[extern, c_abi]]
void free(void* pointer);

/// Allocate raw storage for one `T`. The block is uninitialized.
/// Returns `(pointer, true)` on success and `(nullptr, false)` on failure.
(T*, bool) std::memory::allocate<T>() {
    auto ptr = malloc(sizeof(T)) as T*;
    return (ptr, ptr != nullptr);
}

/// Allocate raw storage for `count` values of `T`. The block is uninitialized.
/// Returns `(pointer, true)` on success and `(nullptr, false)` on failure.
(T*, bool) std::memory::allocate<T>(ulong count) {
    if (count == 0) {
        return (nullptr, true);
    }
    auto ptr = malloc(sizeof(T) * (count as size_t)) as T*;
    return (ptr, ptr != nullptr);
}

/// Allocate zero-initialized storage for `count` values of `T`.
(T*, bool) std::memory::allocate_zeroed<T>(ulong count) {
    if (count == 0) {
        return (nullptr, true);
    }
    auto ptr = calloc(count as size_t, sizeof(T)) as T*;
    return (ptr, ptr != nullptr);
}

/// Grow or shrink raw storage. When `pointer` is null this behaves like
/// `std::memory::allocate<T>(count)`. Returns `(pointer, true)` on success.
(T*, bool) std::memory::reallocate<T>(T* pointer, ulong count) {
    if (count == 0) {
        if (pointer != nullptr) {
            pointer.free();
        }
        return (nullptr, true);
    }
    auto ptr = realloc(pointer as void*, sizeof(T) * (count as size_t)) as T*;
    return (ptr, ptr != nullptr);
}

/// Allocate one value of `T` and copy `value` into it.
(T*, bool) std::memory::allocate_value<T>(T value) {
    auto (ptr, isOk) = std::memory::allocate<T>();
    if (!isOk) {
        return (nullptr, false);
    }
    ptr[0] = value;
    return (ptr, true);
}

/// Release raw storage obtained from this module. Null pointers are ignored.
void std::memory::free_raw<T>(T* pointer) {
    if (pointer != nullptr) {
        pointer.free();
    }
}
