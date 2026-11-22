
import std.string.prelude;
import std.string.len;
import std.memory.owned;

[[extern, c_abi]]
char* strdup(const char* src);

[[extern, c_abi]]
char* strndup(const char* src, size_t count);


Result<std::memory::Owned<char>> std::string::dup(const char* src) {
    auto ptr = src.strdup(); 
    if (ptr == nullptr) {
        return std::error("std::string::dup: Failed to duplicate string");
    }
    return std::ok(std::memory::Owned{ptr, src.length() + 1});
}

Result<std::memory::Owned<char>> std::string::dup(const char* src, ulong count) {
    auto ptr = src.strndup(count); 
    if (ptr == nullptr) {
        return std::error("std::string::dup: Failed to duplicate string");
    }
    return std::ok(std::memory::Owned{ptr, ptr.length() + 1});
}

Result<std::memory::Owned<char>> dup(const char* str) => std::string::dup(str);
Result<std::memory::Owned<char>> dup(const char* str, ulong count) => std::string::dup(str, count);
