
import std.string.prelude;

[[extern, c_abi]]
size_t strlen(const char* s);

size_t std::string::length(const char* s) => s.strlen();
size_t length(const char* s) => s.strlen();