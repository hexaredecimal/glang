import std.string.prelude;
import std.string.owned;
import std.result;

/// Duplicate `src` into a newly allocated `String`.
Result<String> std::string::dup(const char* src) =>
    std::string::own(src);

/// Duplicate at most `count` characters of `src`.
Result<String> std::string::dup(const char* src, ulong count) =>
    std::string::own(src, count);

Result<String> dup(const char* str) => std::string::dup(str);
Result<String> dup(const char* str, ulong count) => std::string::dup(str, count);
