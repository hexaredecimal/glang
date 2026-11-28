import std.memory.prelude;
import std.memory.c.alloc;
import std.memory.c.mem;
import std.result;

/// A *user-owned* memory block. Receiving an `Owned<T>` transfers
/// responsibility for releasing it with `std::memory::release`.
///
/// The block contains `count` indexable slots. Use `std::memory::alloc` for
/// uninitialized storage, `std::memory::alloc_value` for a single initialized
/// value, and `std::memory::adopt` to take over a pointer produced elsewhere.
struct std::memory::Owned<T> {
    /// Pointer to the heap block. `release` frees this pointer.
    T* ptr;

    /// Number of indexable slots in the block.
    size_t count;
}

type Owned<T> = std::memory::Owned<T>;

/// Allocate one uninitialized value of `T`.
Result<Owned<T>> std::memory::alloc<T>() => std::memory::alloc<T>(1 as size_t);

/// Allocate `count` uninitialized values of `T`.
Result<Owned<T>> std::memory::alloc<T>(size_t count) {
    auto (ptr, isOk) = std::memory::allocate<T>(count as ulong);
    if (!isOk) {
        return std::error("std::memory::alloc: Failed to allocate memory");
    }
    return std::ok(Owned<T>{ptr, count});
}

/// Allocate `count` zero-initialized values of `T`.
Result<Owned<T>> std::memory::alloc_zeroed<T>(size_t count) {
    auto (ptr, isOk) = std::memory::allocate_zeroed<T>(count as ulong);
    if (!isOk) {
        return std::error("std::memory::alloc_zeroed: Failed to allocate memory");
    }
    return std::ok(Owned<T>{ptr, count});
}

/// Allocate one value of `T` and initialize it with `value`.
Result<Owned<T>> std::memory::alloc_value<T>(T value) {
    auto (ptr, isOk) = std::memory::allocate_value<T>(value);
    if (!isOk) {
        return std::error("std::memory::alloc_value: Failed to allocate memory");
    }
    return std::ok(Owned<T>{ptr, 1});
}

/// Take ownership of `ptr`, which must point to at least `count` slots of `T`.
Result<Owned<T>> std::memory::adopt<T>(T* ptr, size_t count) {
    if (ptr == nullptr && count != 0) {
        return std::error("std::memory::adopt: Cannot own a null pointer");
    }
    return std::ok(Owned<T>{ptr, count});
}

/// True when the block does not point at any storage.
bool std::memory::is_null<T>(Owned<T> owned) => owned.ptr == nullptr;

/// The raw pointer held by `owned`.
T* std::memory::get<T>(Owned<T> owned) => owned.ptr;

/// The number of indexable slots in `owned`.
size_t std::memory::get_count<T>(Owned<T> owned) => owned.count;

/// Grow or shrink `owned` to `count` slots. Existing contents are preserved.
/// Returns false when the allocation fails; the block is left unchanged.
bool std::memory::resize<T>(Owned<T>* owned, size_t count) {
    if (owned == nullptr) {
        return false;
    }
    auto (ptr, isOk) = std::memory::reallocate<T>(owned.ptr, count as ulong);
    if (!isOk) {
        return false;
    }
    owned.ptr = ptr;
    owned.count = count;
    return true;
}

/// Move the pointer out of `owned`, leaving it empty. The caller becomes
/// responsible for releasing the returned pointer.
T* std::memory::take<T>(Owned<T>* owned) {
    if (owned == nullptr) {
        return nullptr;
    }
    T* ptr = owned.ptr;
    owned.ptr = nullptr;
    owned.count = 0;
    return ptr;
}

/// Free the block and reset `owned` to an empty state.
void std::memory::release<T>(Owned<T>* owned) {
    if (owned == nullptr) {
        return;
    }
    if (owned.ptr != nullptr) {
        owned.ptr.free();
    }
    owned.ptr = nullptr;
    owned.count = 0;
}

/// Copy `source` into a newly allocated block.
Result<Owned<T>> std::memory::clone<T>(Owned<T> source) {
    auto (ptr, isOk) = std::memory::allocate<T>(source.count as ulong);
    if (!isOk) {
        return std::error("std::memory::clone: Failed to allocate memory");
    }
    if (source.ptr != nullptr && source.count > 0) {
        std::memory::memcpy(ptr, source.ptr, (source.count as ulong) * (sizeof(T) as ulong));
    }
    return std::ok(Owned<T>{ptr, source.count});
}

// Free-function forms. These keep the API usable through UFCS, for example
// `owned.release()`, `owned.get()`, and `owned.take()`.

Result<Owned<T>> alloc<T>() => std::memory::alloc<T>();
Result<Owned<T>> alloc<T>(size_t count) => std::memory::alloc<T>(count);
Result<Owned<T>> alloc_zeroed<T>(size_t count) => std::memory::alloc_zeroed<T>(count);
Result<Owned<T>> alloc_value<T>(T value) => std::memory::alloc_value<T>(value);
Result<Owned<T>> adopt<T>(T* ptr, size_t count) => std::memory::adopt<T>(ptr, count);
bool is_null<T>(Owned<T> owned) => std::memory::is_null(owned);
T* get<T>(Owned<T> owned) => std::memory::get(owned);
size_t get_count<T>(Owned<T> owned) => std::memory::get_count(owned);
bool resize<T>(Owned<T>* owned, size_t count) => std::memory::resize(owned, count);
T* take<T>(Owned<T>* owned) => std::memory::take(owned);
void release<T>(Owned<T>* owned) => std::memory::release(owned);
Result<Owned<T>> clone<T>(Owned<T> source) => std::memory::clone(source);
