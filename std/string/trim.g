import std.string.prelude;
import std.string.string;
import std.string.len;
import std.chars.types;

/// True when the string is empty or contains only whitespace.
bool std::string::is_blank(const char* text) {
    if (text == nullptr) {
        return true;
    }
    int index = 0;
    while (text[index] != '\0') {
        if (!std::chars::is_space(text[index])) {
            return false;
        }
        index = index + 1;
    }
    return true;
}

/// Copy of `text` without leading whitespace. The input is not modified.
String std::string::trim_left(const char* text) {
    if (text == nullptr) {
        return String::new();
    }
    int start = 0;
    while (text[start] != '\0' && std::chars::is_space(text[start])) {
        start = start + 1;
    }
    return String::from(text + start);
}

/// Copy of `text` without trailing whitespace. The input is not modified.
String std::string::trim_right(const char* text) {
    if (text == nullptr) {
        return String::new();
    }
    int length = std::string::length(text) as int;
    while (length > 0 && std::chars::is_space(text[length - 1])) {
        length = length - 1;
    }
    return String::from(text, length as ulong);
}

/// Copy of `text` without leading or trailing whitespace.
String std::string::trim(const char* text) {
    auto left = std::string::trim_left(text);
    return std::string::trim_right(left.c_str());
}

/// Copy of `text` without leading occurrences of `character`.
String std::string::trim_left(const char* text, char character) {
    if (text == nullptr) {
        return String::new();
    }
    int start = 0;
    while (text[start] == character) {
        start = start + 1;
    }
    return String::from(text + start);
}

/// Copy of `text` without trailing occurrences of `character`.
String std::string::trim_right(const char* text, char character) {
    if (text == nullptr) {
        return String::new();
    }
    int length = std::string::length(text) as int;
    while (length > 0 && text[length - 1] == character) {
        length = length - 1;
    }
    return String::from(text, length as ulong);
}

/// Copy of `text` without leading or trailing occurrences of `character`.
String std::string::trim(const char* text, char character) {
    auto left = std::string::trim_left(text, character);
    return std::string::trim_right(left.c_str(), character);
}

// String-receiver overloads make the same operations available through UFCS
// without converting to a C string at the call site.

bool String::is_blank(String* self) =>
    std::string::is_blank(String::c_str(self));

String String::trim_left(String* self) =>
    std::string::trim_left(String::c_str(self));
String String::trim_right(String* self) =>
    std::string::trim_right(String::c_str(self));
String String::trim(String* self) =>
    std::string::trim(String::c_str(self));
String String::trim_left(String* self, char character) =>
    std::string::trim_left(String::c_str(self), character);
String String::trim_right(String* self, char character) =>
    std::string::trim_right(String::c_str(self), character);
String String::trim(String* self, char character) =>
    std::string::trim(String::c_str(self), character);

bool is_blank(const char* text) => std::string::is_blank(text);
String trim_left(const char* text) => std::string::trim_left(text);
String trim_right(const char* text) => std::string::trim_right(text);
String trim(const char* text) => std::string::trim(text);
String trim_left(const char* text, char character) =>
    std::string::trim_left(text, character);
String trim_right(const char* text, char character) =>
    std::string::trim_right(text, character);
String trim(const char* text, char character) =>
    std::string::trim(text, character);
