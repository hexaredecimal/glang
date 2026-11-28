import std.string.prelude;
import std.string.string;
import std.result;

/// Copy `str` into a newly allocated `String`.
///
/// The only failure is a null input, so `own` keeps the fallible signature
/// used by callers that validate external C strings. Prefer `String::from`
/// when the input is known to be non-null.
Result<String> std::string::own(const char* str) {
    if (str == nullptr) {
        return std::error("std::string::own: Cannot own a null string");
    }
    return std::ok(String::from(str));
}

/// Copy at most `count` characters of `str` into a newly allocated `String`.
Result<String> std::string::own(const char* str, ulong count) {
    if (str == nullptr) {
        return std::error("std::string::own: Cannot own a null string");
    }
    return std::ok(String::from(str, count));
}

Result<String> own(const char* str) => std::string::own(str);
Result<String> own(const char* str, ulong count) => std::string::own(str, count);
