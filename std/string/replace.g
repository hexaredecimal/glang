import std.string.prelude;

/// Replace every occurrence of `from` with `to` in place.
/// Returns the number of bytes replaced.
int std::string::replace_char(char* text, char from, char to) {
    if (text == nullptr) {
        return 0;
    }
    int total = 0;
    int index = 0;
    while (text[index] != '\0') {
        if (text[index] == from) {
            text[index] = to;
            total = total + 1;
        }
        index = index + 1;
    }
    return total;
}

int replace_char(char* text, char from, char to) => std::string::replace_char(text, from, to);
