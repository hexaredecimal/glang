import std.string.prelude;
import std.string.string;

/// Deep-copy `src` into a new `String`.
String std::string::clone(const char* src) => String::from(src);

/// Deep-copy at most `count` characters of `src`.
String std::string::clone(const char* src, ulong count) =>
    String::from(src, count);

String clone(const char* str) => std::string::clone(str);
String clone(const char* str, ulong count) => std::string::clone(str, count);
