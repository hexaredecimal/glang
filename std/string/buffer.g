import std.string.prelude;
import std.string.len;
import std.chars.types;

/// Safely copy `src` into fixed-capacity buffer `dst`, always NUL-terminating
/// when `cap > 0`. Returns the number of characters written (excluding NUL).
int std::string::copy(char* dst, const char* src, int cap) {
    if (dst == nullptr || cap <= 0) {
        return 0;
    }
    if (src == nullptr) {
        dst[0] = '\0';
        return 0;
    }
    int i = 0;
    while (src[i] != '\0' && i < cap - 1) {
        dst[i] = src[i];
        i = i + 1;
    }
    dst[i] = '\0';
    return i;
}

/// Safely append `src` onto the NUL-terminated string in `dst` up to `cap`.
/// Returns the resulting string length in `dst`.
int std::string::append_into(char* dst, const char* src, int cap) {
    if (dst == nullptr || cap <= 0) {
        return 0;
    }
    int len = dst.length() as int;
    if (len >= cap) {
        len = cap - 1;
        dst[len] = '\0';
    }
    if (src == nullptr) {
        return len;
    }
    int i = 0;
    while (src[i] != '\0' && len + i < cap - 1) {
        dst[len + i] = src[i];
        i = i + 1;
    }
    dst[len + i] = '\0';
    return len + i;
}

/// Format base-10 signed integer `value` into `dst` (bounded by `cap`).
/// Returns the number of characters written (excluding NUL).
int std::string::format_int(char* dst, int value, int cap) {
    if (dst == nullptr || cap <= 0) {
        return 0;
    }
    if (cap == 1) {
        dst[0] = '\0';
        return 0;
    }
    int pos = 0;
    long mag = value as long;
    if (mag < 0) {
        dst[pos] = '-';
        pos = pos + 1;
        mag = -mag;
    }
    char[24] digits;
    int d = 0;
    if (mag == 0) {
        digits[0] = '0';
        d = 1;
    } else {
        while (mag > 0 && d < 23) {
            int rem = (mag % 10) as int;
            digits[d] = (48 + rem) as char;
            mag = mag / 10;
            d = d + 1;
        }
    }
    while (d > 0 && pos < cap - 1) {
        d = d - 1;
        dst[pos] = digits[d];
        pos = pos + 1;
    }
    dst[pos] = '\0';
    return pos;
}

/// Copy `src` into `dst` transforming ASCII case (`1` = upper, `2` = lower,
/// `3` = title case, anything else = unchanged). Returns characters written
/// (excluding NUL).
int std::string::copy_case(char* dst, const char* src, int textCase, int cap) {
    if (dst == nullptr || cap <= 0) {
        return 0;
    }
    if (src == nullptr) {
        dst[0] = '\0';
        return 0;
    }
    int i = 0;
    bool wordStart = true;
    while (src[i] != '\0' && i < cap - 1) {
        char c = src[i];
        if (textCase == 1) {
            c = std::chars::to_upper(c);
        } else if (textCase == 2) {
            c = std::chars::to_lower(c);
        } else if (textCase == 3) {
            if (std::chars::is_alphabet(c)) {
                if (wordStart) {
                    c = std::chars::to_upper(c);
                    wordStart = false;
                } else {
                    c = std::chars::to_lower(c);
                }
            } else if (std::chars::is_alphanumeric(c)) {
                wordStart = false;
            } else {
                wordStart = true;
            }
        }
        dst[i] = c;
        i = i + 1;
    }
    dst[i] = '\0';
    return i;
}

int copy_into(char* dst, const char* src, int cap) => std::string::copy(dst, src, cap);
int append_into(char* dst, const char* src, int cap) => std::string::append_into(dst, src, cap);
int format_int(char* dst, int value, int cap) => std::string::format_int(dst, value, cap);
int copy_case(char* dst, const char* src, int textCase, int cap) =>
    std::string::copy_case(dst, src, textCase, cap);
