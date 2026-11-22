
import std.memory.prelude;


[[extern, c_abi]]
void* malloc(size_t size);

(T*, bool) std::memory::allocate<T>() {
  auto ptr = malloc(sizeof(T)) as T*;
  return (ptr, ptr != nullptr);
}

(T*, bool) std::memory::allocate<T>(ulong count) {
  auto ptr = malloc(sizeof(T) * count) as T*;
  return (ptr, ptr != nullptr);
}

[[extern, c_abi]]
void* calloc(size_t count, size_t size);

[[extern, c_abi]]
void free(void*);
