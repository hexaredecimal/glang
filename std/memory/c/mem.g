
import std.memory.prelude;

[[extern]]
void* std::memory::memset(void* dst, int value, ulong size);

[[extern]]
void* std::memory::memcpy(void* dst, const void* src, ulong size);

[[extern]]
void* std::memory::memmove(void* dst, void* src, ulong size);

[[extern]]
int std::memory::memcmp(void* buf1, void* buf2, ulong size);

[[extern]]
void* std::memory::memchr(void* buf, ulong size);
