
import std.memory.prelude;
import std.memory.c.alloc;
import std.result; 


/// Represents a *user-owned* memory block. 
/// If a function handle you this type, it means you are
/// responsible of *releasing* the memory.  
struct std::memory::Owned<T> {
    ///  The pointer to the memory region allocated on the heap.
    /// *release* free's this pointer's memory block
    T* ptr; 

    /// The count of indexible slots within this allocation.
    /// Call std::memory::make_owned<T>(count) to allocate a array-like region.
    size_t count;
}

type Owned<T> = std::memory::Owned<T>; 
 
Result<std::memory::Owned<T>> std::memory::owned_value<T>(T value) {
    auto (ptr, isOk) =  std::memory::allocate<T>();
    if (!isOk) {
        return std::error("std::memory::owned_value<T>: Failed to allocate memory");
    };
    *ptr = value;
    return std::ok(std::memory::Owned{ptr, 1});
}

Result<std::memory::Owned<T>> std::memory::owned_ptr<T>(T* ptr, size_t count) {
    if (ptr == nullptr) {
        return std::error("std::memory::owned_ptr: Cannot own a null pointer");
    };
    return std::ok(std::memory::Owned{ptr, count});
}

Result<std::memory::Owned<T>> to_owned_ptr<T>(T* ptr, size_t count) => std::memory::owned_ptr(ptr, count);


Result<std::memory::Owned<T>> std::memory::make_owned<T>() {
    auto (ptr, isOk) = std::memory::allocate<T>();
    if (!isOk) {
        return std::error("std::memory::make_owned: Failed to allocate memory");
    };
    return std::ok(std::memory::Owned{ptr, 1});
}

Result<std::memory::Owned<T>> std::memory::make_owned<T>(T init) {
    auto (ptr, isOk) = std::memory::allocate<T>();
    if (!isOk) {
        return std::error("std::memory::make_owned: Failed to allocate memory");
    };

    *ptr = init; 
    return std::ok(std::memory::Owned{ptr, 1});
}

Result<std::memory::Owned<T>> std::memory::make_owned<T>(size_t count) {
    auto (ptr, isOk) = std::memory::allocate<T>(count);
    if (!isOk) {
        return std::error("std::memory::make_owned: Failed to allocate memory");
    };
    return std::ok(std::memory::Owned{ptr, count});
}

T* std::memory::get<T>(std::memory::Owned<T> owned) {
    return owned.ptr;
}

Result<std::memory::Owned<T>> std::make_owned<T>() => std::memory::make_owned<T>()
Result<std::memory::Owned<T>> std::make_owned<T>(T init) => std::memory::make_owned(init)
Result<std::memory::Owned<T>> std::make_owned<T>(size_t count) => std::memory::make_owned(count)

size_t std::memory::get_count<T>(std::memory::Owned<T> owned) {
    return owned.count;
}

void std::memory::release<T>(std::memory::Owned<T>* owned) {
    if (owned.ptr) {
        owned.ptr.free();
        owned.ptr = nullptr;
    }
    owned.count = 0;
}


Result<std::memory::Owned<T>> std::memory::to_owned<T>(T value) => std::memory::owned_value(value);
Result<std::memory::Owned<T>> to_owned<T>(T value) => std::memory::to_owned(value);
Result<std::memory::Owned<T>> std::memory::allocate_owned<T>() => std::memory::make_owned<T>();
Result<std::memory::Owned<T>> std::memory::allocate_owned<T>(size_t count) => std::memory::make_owned<T>(count);
Result<std::memory::Owned<T>> allocate_owned<T>() => std::memory::make_owned<T>();
Result<std::memory::Owned<T>> allocate_owned<T>(size_t count) => std::memory::make_owned<T>(count);

Result<std::memory::Owned<T>> std::memory::fromValue<T>(T value) => std::memory::owned_value(value);
Result<std::memory::Owned<T>> fromValue<T>(T value) => std::memory::owned_value(value);
Result<std::memory::Owned<T>> std::memory::fromPtr<T>(T* ptr, size_t count) => std::memory::owned_ptr(ptr, count);
Result<std::memory::Owned<T>> fromPtr<T>(T* ptr, size_t count) => std::memory::owned_ptr(ptr, count);
Result<std::memory::Owned<T>> std::memory::allocateOwned<T>() => std::memory::make_owned<T>();
Result<std::memory::Owned<T>> std::memory::allocateOwned<T>(size_t count) => std::memory::make_owned<T>(count);
Result<std::memory::Owned<T>> allocateOwned<T>() => std::memory::make_owned<T>();
Result<std::memory::Owned<T>> allocateOwned<T>(size_t count) => std::memory::make_owned<T>(count);

void release<T>(std::memory::Owned<T>* owned) => std::memory::release(owned);
T* get<T>(std::memory::Owned<T> owned) => std::memory::get<T>(owned);
size_t get_count<T>(std::memory::Owned<T> owned) => std::memory::get_count(owned);
