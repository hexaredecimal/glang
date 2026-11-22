import std.string.prelude;
import std.chars.types;

/// Lexicographic comparison. Returns -1, 0, or 1.
int std::string::compare(const char* left, const char* right) {
    if (left == nullptr && right == nullptr) {
        return 0;
    }
    if (left == nullptr) {
        return -1;
    }
    if (right == nullptr) {
        return 1;
    }
    int index = 0;
    while (left[index] != '\0' && right[index] != '\0') {
        if (left[index] < right[index]) {
            return -1;
        }
        if (left[index] > right[index]) {
            return 1;
        }
        index = index + 1;
    }
    if (left[index] == '\0' && right[index] == '\0') {
        return 0;
    }
    if (left[index] == '\0') {
        return -1;
    }
    return 1;
}

/// Case-insensitive lexicographic comparison for ASCII text.
int std::string::compare_ignore_case(const char* left, const char* right) {
    if (left == nullptr && right == nullptr) {
        return 0;
    }
    if (left == nullptr) {
        return -1;
    }
    if (right == nullptr) {
        return 1;
    }
    int index = 0;
    while (left[index] != '\0' && right[index] != '\0') {
        char a = std::chars::to_lower(left[index]);
        char b = std::chars::to_lower(right[index]);
        if (a < b) {
            return -1;
        }
        if (a > b) {
            return 1;
        }
        index = index + 1;
    }
    if (left[index] == '\0' && right[index] == '\0') {
        return 0;
    }
    if (left[index] == '\0') {
        return -1;
    }
    return 1;
}

bool std::string::equals_ignore_case(const char* left, const char* right) =>
    std::string::compare_ignore_case(left, right) == 0;

bool std::string::is_empty(const char* text) {
    if (text == nullptr) {
        return true;
    }
    return text[0] == '\0';
}

int compare_strings(const char* left, const char* right) => std::string::compare(left, right);
int compare_ignore_case(const char* left, const char* right) => std::string::compare_ignore_case(left, right);
bool equals_ignore_case(const char* left, const char* right) => std::string::equals_ignore_case(left, right);
bool is_empty_string(const char* text) => std::string::is_empty(text);
