
import std.prelude;
import std.string.len;

/// Hashing module namespace.
struct std::hashing {}

// FNV-1a 32-bit constants.
uint hashing_fnv_offset() => 2166136261;
uint hashing_fnv_prime() => 16777619;

/// FNV-1a hash of `length` bytes starting at `data`. Embedded NUL bytes are
/// hashed normally.
uint std::hashing::bytes(const char* data, int length) {
    uint hash = 2166136261;
    if (data == nullptr || length <= 0) {
        return hash;
    }
    for (int index = 0; index < length; index = index + 1) {
        hash = hash ^ (((data[index] as uchar) as uint));
        hash = hash * 16777619;
    }
    return hash;
}

uint hash_bytes(const char* data, int length) =>
    std::hashing::bytes(data, length);

/// FNV-1a hash of a NUL-terminated string. A null pointer hashes like the
/// empty string.
uint std::hashing::string(const char* text) {
    if (text == nullptr) {
        return 2166136261;
    }
    return std::hashing::bytes(text, text.length() as int);
}

uint hash_string(const char* text) => std::hashing::string(text);

/// djb2 hash of `length` bytes. This 64-bit variant is useful when a wider
/// hash reduces collisions in user-built tables.
ulong std::hashing::bytes64(const char* data, int length) {
    ulong hash = 5381;
    if (data == nullptr || length <= 0) {
        return hash;
    }
    for (int index = 0; index < length; index = index + 1) {
        hash = hash * 33 + (((data[index] as uchar) as ulong));
    }
    return hash;
}

ulong hash_bytes64(const char* data, int length) =>
    std::hashing::bytes64(data, length);

/// djb2 hash of a NUL-terminated string. A null pointer hashes like the empty
/// string.
ulong std::hashing::string64(const char* text) {
    if (text == nullptr) {
        return 5381;
    }
    return std::hashing::bytes64(text, text.length() as int);
}

ulong hash_string64(const char* text) => std::hashing::string64(text);

/// Mix an integer into a 32-bit hash. The avalanche steps make small changes
/// in the input affect many output bits.
uint std::hashing::integer(int value) {
    uint hash = value as uint;
    hash = ((hash >> 16) ^ hash) * 73244475;
    hash = ((hash >> 16) ^ hash) * 73244475;
    hash = (hash >> 16) ^ hash;
    return hash;
}

uint hash_int(int value) => std::hashing::integer(value);

/// Combine a running hash with another value.
uint std::hashing::combine(uint seed, uint value) =>
    seed ^ (value + 2654435769 + (seed << 6) + (seed >> 2));

uint hash_combine(uint seed, uint value) =>
    std::hashing::combine(seed, value);
