import std.string.prelude;
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

/// Remove leading whitespace by shifting the remaining bytes left.
void std::string::trim_left(char* text) {
    if (text == nullptr) {
        return;
    }
    int start = 0;
    while (text[start] != '\0' && std::chars::is_space(text[start])) {
        start = start + 1;
    }
    if (start == 0) {
        return;
    }
    int index = 0;
    while (text[start + index] != '\0') {
        text[index] = text[start + index];
        index = index + 1;
    }
    text[index] = '\0';
}

/// Remove trailing whitespace by writing an earlier terminator.
void std::string::trim_right(char* text) {
    if (text == nullptr) {
        return;
    }
    int length = text.length() as int;
    while (length > 0 && std::chars::is_space(text[length - 1])) {
        length = length - 1;
    }
    text[length] = '\0';
}

void std::string::trim(char* text) {
    std::string::trim_left(text);
    std::string::trim_right(text);
}

/// Remove leading occurrences of `character`.
void std::string::trim_left(char* text, char character) {
    if (text == nullptr) {
        return;
    }
    int start = 0;
    while (text[start] == character) {
        start = start + 1;
    }
    if (start == 0) {
        return;
    }
    int index = 0;
    while (text[start + index] != '\0') {
        text[index] = text[start + index];
        index = index + 1;
    }
    text[index] = '\0';
}

/// Remove trailing occurrences of `character`.
void std::string::trim_right(char* text, char character) {
    if (text == nullptr) {
        return;
    }
    int length = text.length() as int;
    while (length > 0 && text[length - 1] == character) {
        length = length - 1;
    }
    text[length] = '\0';
}

void std::string::trim(char* text, char character) {
    std::string::trim_left(text, character);
    std::string::trim_right(text, character);
}

bool is_blank(const char* text) => std::string::is_blank(text);
void trim_left(char* text) => std::string::trim_left(text);
void trim_right(char* text) => std::string::trim_right(text);
void trim(char* text) => std::string::trim(text);
void trim_left(char* text, char character) => std::string::trim_left(text, character);
void trim_right(char* text, char character) => std::string::trim_right(text, character);
void trim(char* text, char character) => std::string::trim(text, character);
