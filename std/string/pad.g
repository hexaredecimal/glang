
import std.string.prelude;
import std.string.len;
import std.string.builder;

/// Pad `text` on the left to `width` bytes with `fill`.
StringBuilder pad_left(const char* text, int width, char fill) {
    StringBuilder result = StringBuilder::new();
    if (text == nullptr) {
        return result;
    }
    int length = text.length() as int;
    for (int count = length; count < width; count = count + 1) {
        result = builder_append_char(result, fill);
    }
    return builder_append_text(result, text);
}

StringBuilder pad_start(const char* text, int width, char fill) =>
    pad_left(text, width, fill);

/// Pad `text` on the right to `width` bytes with `fill`.
StringBuilder pad_right(const char* text, int width, char fill) {
    StringBuilder result = builder_from(text);
    if (text == nullptr) {
        return result;
    }
    int length = text.length() as int;
    for (int count = length; count < width; count = count + 1) {
        result = builder_append_char(result, fill);
    }
    return result;
}

StringBuilder pad_end(const char* text, int width, char fill) =>
    pad_right(text, width, fill);

/// Center `text` in `width` bytes. When the padding is odd, the extra byte
/// goes on the right.
StringBuilder pad_center(const char* text, int width, char fill) {
    StringBuilder result = StringBuilder::new();
    if (text == nullptr) {
        return result;
    }
    int length = text.length() as int;
    if (length >= width) {
        return builder_from(text);
    }
    int leftPadding = (width - length) / 2;
    int rightPadding = width - length - leftPadding;
    for (int count = 0; count < leftPadding; count = count + 1) {
        result = builder_append_char(result, fill);
    }
    result = builder_append_text(result, text);
    for (int count = 0; count < rightPadding; count = count + 1) {
        result = builder_append_char(result, fill);
    }
    return result;
}

/// Pad a number-like string with leading zeros. A leading `+` or `-` stays in
/// front of the padding.
StringBuilder zfill(const char* text, int width) {
    if (text == nullptr) {
        return StringBuilder::new();
    }
    int length = text.length() as int;
    if (length >= width) {
        return builder_from(text);
    }
    if (text[0] == '+' || text[0] == '-') {
        StringBuilder result = StringBuilder::new();
        result = builder_append_char(result, text[0]);
        int zeros = width - length;
        for (int count = 0; count < zeros; count = count + 1) {
            result = builder_append_char(result, '0');
        }
        for (int count = 1; count < length; count = count + 1) {
            result = builder_append_char(result, text[count]);
        }
        return result;
    }
    return pad_left(text, width, '0');
}

/// Keep at most `width` leading bytes of `text`.
StringBuilder truncate_width(const char* text, int width) {
    StringBuilder result = StringBuilder::new();
    if (text == nullptr || width <= 0) {
        return result;
    }
    int length = text.length() as int;
    int limit = length;
    if (width < limit) {
        limit = width;
    }
    for (int index = 0; index < limit; index = index + 1) {
        result = builder_append_char(result, text[index]);
    }
    return result;
}

/// Repeat `text` `count` times. Non-positive counts produce an empty builder.
StringBuilder repeat_text(const char* text, int count) {
    StringBuilder result = StringBuilder::new();
    if (text == nullptr || count <= 0) {
        return result;
    }
    for (int index = 0; index < count; index = index + 1) {
        result = builder_append_text(result, text);
    }
    return result;
}
