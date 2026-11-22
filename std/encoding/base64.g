
import std.encoding.prelude;
import std.string.len;

/// Map a 6-bit value to its Base64 character. Out-of-range values become 'A'.
char base64_digit(int value) {
    int index = value;
    if (index < 0 || index > 63) {
        index = 0;
    }
    if (index < 26) {
        return (('A' as int) + index) as char;
    }
    if (index < 52) {
        return (('a' as int) + index - 26) as char;
    }
    if (index < 62) {
        return (('0' as int) + index - 52) as char;
    }
    if (index == 62) {
        return '+';
    }
    return '/';
}

/// Decode one Base64 character, or -1 when it is not part of the alphabet.
int base64_value(char character) {
    int code = character as int;
    if (code >= 65 && code <= 90) {
        return code - 65;
    }
    if (code >= 97 && code <= 122) {
        return code - 71;
    }
    if (code >= 48 && code <= 57) {
        return code + 4;
    }
    if (code == 43) {
        return 62;
    }
    if (code == 47) {
        return 63;
    }
    return -1;
}

/// Number of characters produced by `base64_encode`, excluding the NUL.
int base64_encoded_length(const char* text) {
    if (text == nullptr) {
        return 0;
    }
    int length = text.length() as int;
    return ((length + 2) / 3) * 4;
}

/// Number of bytes produced by decoding `text`, or -1 when the input is not
/// valid padded Base64.
int base64_decoded_length(const char* text) {
    if (text == nullptr) {
        return -1;
    }
    int length = text.length() as int;
    if (length == 0) {
        return 0;
    }
    if (length % 4 != 0) {
        return -1;
    }
    int padding = 0;
    if (text[length - 1] == '=') {
        padding = padding + 1;
    }
    if (length >= 2 && text[length - 2] == '=') {
        padding = padding + 1;
    }
    if (padding > 2) {
        return -1;
    }
    int content = length - padding;
    for (int index = 0; index < content; index = index + 1) {
        if (base64_value(text[index]) < 0) {
            return -1;
        }
    }
    for (int index = content; index < length; index = index + 1) {
        if (text[index] != '=') {
            return -1;
        }
    }
    return (length / 4) * 3 - padding;
}

/// True when `text` is valid padded Base64. The empty string is valid.
bool base64_valid(const char* text) => base64_decoded_length(text) >= 0;

/// Encode the bytes of `text` as padded Base64. The output is NUL-terminated
/// when it fits. Returns the number of characters written, or -1 when the
/// buffer is too small or an argument is null.
int std::encoding::base64_encode(const char* text, char* output,
                                 int output_capacity) {
    if (text == nullptr || output == nullptr || output_capacity <= 0) {
        return -1;
    }
    int length = text.length() as int;
    int needed = base64_encoded_length(text);
    if (needed + 1 > output_capacity) {
        return -1;
    }

    int source = 0;
    int target = 0;
    while (source + 2 < length) {
        int first = (text[source] as uchar) as int;
        int second = (text[source + 1] as uchar) as int;
        int third = (text[source + 2] as uchar) as int;
        int triple = (first << 16) | (second << 8) | third;
        output[target] = base64_digit((triple >> 18) & 63);
        output[target + 1] = base64_digit((triple >> 12) & 63);
        output[target + 2] = base64_digit((triple >> 6) & 63);
        output[target + 3] = base64_digit(triple & 63);
        source = source + 3;
        target = target + 4;
    }

    int remaining = length - source;
    if (remaining == 1) {
        int first = (text[source] as uchar) as int;
        int triple = first << 16;
        output[target] = base64_digit((triple >> 18) & 63);
        output[target + 1] = base64_digit((triple >> 12) & 63);
        output[target + 2] = '=';
        output[target + 3] = '=';
        target = target + 4;
    } else if (remaining == 2) {
        int first = (text[source] as uchar) as int;
        int second = (text[source + 1] as uchar) as int;
        int triple = (first << 16) | (second << 8);
        output[target] = base64_digit((triple >> 18) & 63);
        output[target + 1] = base64_digit((triple >> 12) & 63);
        output[target + 2] = base64_digit((triple >> 6) & 63);
        output[target + 3] = '=';
        target = target + 4;
    }

    output[needed] = '\0';
    return needed;
}

int base64_encode(const char* text, char* output, int output_capacity) =>
    std::encoding::base64_encode(text, output, output_capacity);

/// Decode padded Base64 into bytes. The output is NUL-terminated when it fits.
/// Returns the number of bytes written, or -1 for invalid input, a null
/// argument, or an insufficient buffer.
int std::encoding::base64_decode(const char* text, char* output,
                                 int output_capacity) {
    if (text == nullptr || output == nullptr || output_capacity <= 0) {
        return -1;
    }
    int length = text.length() as int;
    if (length == 0) {
        output[0] = '\0';
        return 0;
    }
    int needed = base64_decoded_length(text);
    if (needed < 0 || needed + 1 > output_capacity) {
        return -1;
    }

    int target = 0;
    for (int block = 0; block < length; block = block + 4) {
        int first = base64_value(text[block]);
        int second = base64_value(text[block + 1]);
        bool twoPadding = text[block + 2] == '=';
        bool onePadding = text[block + 3] == '=';
        int third = 0;
        if (!twoPadding) {
            third = base64_value(text[block + 2]);
        }
        int fourth = 0;
        if (!onePadding) {
            fourth = base64_value(text[block + 3]);
        }
        if (first < 0 || second < 0 || third < 0 || fourth < 0) {
            return -1;
        }
        int triple = (first << 18) | (second << 12) | (third << 6) | fourth;
        output[target] = ((triple >> 16) & 255) as char;
        target = target + 1;
        if (!twoPadding) {
            output[target] = ((triple >> 8) & 255) as char;
            target = target + 1;
        }
        if (!onePadding) {
            output[target] = (triple & 255) as char;
            target = target + 1;
        }
    }

    output[needed] = '\0';
    return needed;
}

int base64_decode(const char* text, char* output, int output_capacity) =>
    std::encoding::base64_decode(text, output, output_capacity);
