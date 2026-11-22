import std.string.prelude;
import std.string.conv;
import std.chars.types;

/// True for an optional sign followed by one or more decimal digits.
bool std::string::is_integer(const char* text) {
    if (text == nullptr) {
        return false;
    }
    int index = 0;
    if (text[index] == '+' || text[index] == '-') {
        index = index + 1;
    }
    if (text[index] == '\0') {
        return false;
    }
    while (text[index] != '\0') {
        if (!std::chars::is_digit(text[index])) {
            return false;
        }
        index = index + 1;
    }
    return true;
}

/// True for one or more decimal digits with no sign.
bool std::string::is_unsigned_integer(const char* text) {
    if (text == nullptr || text[0] == '\0') {
        return false;
    }
    int index = 0;
    while (text[index] != '\0') {
        if (!std::chars::is_digit(text[index])) {
            return false;
        }
        index = index + 1;
    }
    return true;
}

/// True for an optional sign, decimal digits, and at most one decimal point.
/// At least one digit is required; `5`, `5.`, `.5`, and `-0.25` are accepted.
bool std::string::is_decimal(const char* text) {
    if (text == nullptr) {
        return false;
    }
    int index = 0;
    if (text[index] == '+' || text[index] == '-') {
        index = index + 1;
    }
    bool sawDigit = false;
    bool sawDot = false;
    while (text[index] != '\0') {
        if (std::chars::is_digit(text[index])) {
            sawDigit = true;
        } else if (text[index] == '.' && !sawDot) {
            sawDot = true;
        } else {
            return false;
        }
        index = index + 1;
    }
    return sawDigit;
}

(int, bool) std::string::parse_int(const char* text) {
    if (!std::string::is_integer(text)) {
        return (0, false);
    }
    return (to_int(text), true);
}

(long, bool) std::string::parse_long(const char* text) {
    if (!std::string::is_integer(text)) {
        return (0, false);
    }
    return (to_long(text), true);
}

(double, bool) std::string::parse_double(const char* text) {
    if (!std::string::is_decimal(text)) {
        return (0.0, false);
    }
    return (to_double(text), true);
}

bool is_integer(const char* text) => std::string::is_integer(text);
bool is_unsigned_integer(const char* text) => std::string::is_unsigned_integer(text);
bool is_decimal(const char* text) => std::string::is_decimal(text);
(int, bool) parse_int(const char* text) => std::string::parse_int(text);
(long, bool) parse_long(const char* text) => std::string::parse_long(text);
(double, bool) parse_double(const char* text) => std::string::parse_double(text);
