import std.string.prelude;
import std.string.len;
import std.chars.types;

[[extern, c_abi]]
int strcmp(const char* s1, const char* s2);

[[extern, c_abi]]
int strncmp(const char* s1, const char* s2, size_t n);

[[no_custom_operators]]
bool std::string::contains(const char* str, const char* substr) {
    if (str == nullptr || substr == nullptr) {
        return false;
    }
    int textLength = str.length() as int;
    int needleLength = substr.length() as int;
    if (needleLength == 0) {
        return true;
    }
    int index = 0;
    while (index + needleLength <= textLength) {
        bool matches = true;
        for (int offset = 0; offset < needleLength; offset = offset + 1) {
            if (str[index + offset] != substr[offset]) {
                matches = false;
                break;
            }
        }
        if (matches) {
            return true;
        }
        index = index + 1;
    }
    return false;
}

[[no_custom_operators]]
bool std::string::contains_ignore_case(const char* str, const char* substr) {
    if (substr == nullptr || substr[0] == '\0') {
        return true;
    }
    if (str == nullptr) {
        return false;
    }
    int textLength = str.length() as int;
    int needleLength = substr.length() as int;
    if (needleLength > textLength) {
        return false;
    }
    int index = 0;
    while (index + needleLength <= textLength) {
        bool matches = true;
        for (int offset = 0; offset < needleLength; offset = offset + 1) {
            if (std::chars::to_lower(str[index + offset]) != std::chars::to_lower(substr[offset])) {
                matches = false;
                break;
            }
        }
        if (matches) {
            return true;
        }
        index = index + 1;
    }
    return false;
}

[[no_custom_operators]]
bool std::string::starts_with(const char* str, const char* prefix) {
    if (str == nullptr || prefix == nullptr) {
        return false;
    }
    size_t plen = prefix.length();
    return strncmp(str, prefix, plen) == 0;
}

[[no_custom_operators]]
bool std::string::ends_with(const char* str, const char* suffix) {
    if (str == nullptr || suffix == nullptr) {
        return false;
    }
    size_t slen = str.length();
    size_t suffix_len = suffix.length();
    if (suffix_len > slen) {
        return false;
    }
    return strcmp(str + (slen - suffix_len), suffix) == 0;
}

[[no_custom_operators]]
bool std::string::equals(const char* s1, const char* s2) {
    if (s1 == nullptr && s2 == nullptr) {
        return true;
    }
    if (s1 == nullptr || s2 == nullptr) {
        return false;
    }
    return strcmp(s1, s2) == 0;
}

[[no_custom_operators]]
int std::string::index_of(const char* str, const char* substr) {
    if (str == nullptr || substr == nullptr) {
        return -1;
    }
    int textLength = str.length() as int;
    int needleLength = substr.length() as int;
    if (needleLength == 0) {
        return 0;
    }
    int index = 0;
    while (index + needleLength <= textLength) {
        bool matches = true;
        for (int offset = 0; offset < needleLength; offset = offset + 1) {
            if (str[index + offset] != substr[offset]) {
                matches = false;
                break;
            }
        }
        if (matches) {
            return index;
        }
        index = index + 1;
    }
    return -1;
}

bool contains(const char* str, const char* substr) => std::string::contains(str, substr);
bool contains_ignore_case(const char* str, const char* substr) =>
    std::string::contains_ignore_case(str, substr);
bool starts_with(const char* str, const char* prefix) => std::string::starts_with(str, prefix);
bool ends_with(const char* str, const char* suffix) => std::string::ends_with(str, suffix);
bool equals(const char* s1, const char* s2) => std::string::equals(s1, s2);
int index_of(const char* str, const char* substr) => std::string::index_of(str, substr);

[[infix_operator]]
bool `==`(const char* s1, const char* s2) => s1.equals(s2)

[[infix_operator]]
bool `!=`(const char* s1, const char* s2) => s1.equals(s2) == false

