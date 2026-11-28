
import std.memory.prelude;

[[extern, c_abi]]
void* std::memory::memset(void* dst, int value, size_t size);

[[extern, c_abi]]
void* std::memory::memcpy(void* dst, const void* src, size_t size);

[[extern, c_abi]]
void* std::memory::memmove(void* dst, const void* src, size_t size);

[[extern, c_abi]]
int std::memory::memcmp(const void* buf1, const void* buf2, size_t size);
