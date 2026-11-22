import std.string.prelude;
import std.string.len;

/// Count occurrences of a single byte.
int std::string::count_char(const char* text, char character) {
    if (text == nullptr) {
        return 0;
    }
    int total = 0;
    int index = 0;
    while (text[index] != '\0') {
        if (text[index] == character) {
            total = total + 1;
        }
        index = index + 1;
    }
    return total;
}

/// Count non-overlapping occurrences of `needle`.
int std::string::count_substring(const char* text, const char* needle) {
    if (text == nullptr || needle == nullptr) {
        return 0;
    }
    int needleLength = needle.length() as int;
    if (needleLength == 0) {
        return 0;
    }
    int textLength = text.length() as int;
    int total = 0;
    int index = 0;
    while (index + needleLength <= textLength) {
        bool matches = true;
        for (int offset = 0; offset < needleLength; offset = offset + 1) {
            if (text[index + offset] != needle[offset]) {
                matches = false;
                break;
            }
        }
        if (matches) {
            total = total + 1;
            index = index + needleLength;
        } else {
            index = index + 1;
        }
    }
    return total;
}

/// Count newline characters.
int std::string::count_lines(const char* text) => std::string::count_char(text, '\n');

int count_char(const char* text, char character) => std::string::count_char(text, character);
int count_substring(const char* text, const char* needle) => std::string::count_substring(text, needle);
int count_lines(const char* text) => std::string::count_lines(text);
