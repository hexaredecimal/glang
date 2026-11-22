import std.memory.owned;
import std.memory.c.mem;
import std.string.dup;
import std.result; 

Result<std::memory::Owned<char>> to_owned(const char* str) {
    auto len = str.strlen();
    auto (ptr, isOk) = std::memory::allocate<char>(len + 1);

    if (!isOk) {
        return std::error("std::string::toOwned: Failed to allocate memory");
    }
    std::memory::memcpy(ptr, str, len + 1);

    return std::ok(std::memory::Owned{ptr, len + 1});
}

Result<std::memory::Owned<char>> toOwned(const char* str) => to_owned(str);

