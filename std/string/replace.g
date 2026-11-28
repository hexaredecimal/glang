import std.string.prelude;
import std.string.string;
import std.string.len;

/// Copy of `text` with every occurrence of `from` replaced by `to`. The
/// input is not modified.
String std::string::replace_char(const char* text, char from, char to) {
    auto result = String::from(text);
    char* buffer = result.data();
    int length = result.size();
    for (int index = 0; index < length; ++index) {
        if (buffer[index] == from) {
            buffer[index] = to;
        }
    }
    return result;
}

/// String-receiver form.
String String::replace_char(String* self, char from, char to) =>
    std::string::replace_char(String::c_str(self), from, to);

String replace_char(const char* text, char from, char to) =>
    std::string::replace_char(text, from, to);
