
import std.encoding.prelude;
import std.string.len;

/// Convert a value in 0..15 to a hexadecimal digit. Out-of-range values
/// produce '0'. The input is clamped rather than rejected so callers can use
/// this as a formatting primitive.
char hex_digit(int value, bool uppercase) {
    int nibble = value;
    if (nibble < 0 || nibble > 15) {
        nibble = 0;
    }
    if (nibble < 10) {
        return (('0' as int) + nibble) as char;
    }
    if (uppercase) {
        return (('A' as int) + nibble - 10) as char;
    }
    return (('a' as int) + nibble - 10) as char;
}

/// Decode one hexadecimal digit, or -1 when the character is not a digit.
int hex_digit_value(char character) {
    int code = character as int;
    if (code >= 48 && code <= 57) {
        return code - 48;
    }
    if (code >= 97 && code <= 102) {
        return code - 87;
    }
    if (code >= 65 && code <= 70) {
        return code - 55;
    }
    return -1;
}

/// Number of characters produced by `hex_encode` for `text`, excluding the
/// terminating NUL. Returns 0 for a null pointer.
int hex_encoded_length(const char* text) {
    if (text == nullptr) {
        return 0;
    }
    return (text.length() as int) * 2;
}

/// Number of bytes produced by `hex_decode` for `text`, or -1 when the text
/// is not valid hexadecimal.
int hex_decoded_length(const char* text) {
    if (text == nullptr) {
        return -1;
    }
    int length = text.length() as int;
    if (length % 2 != 0) {
        return -1;
    }
    return length / 2;
}

/// True when `text` contains exactly an even number of hexadecimal digits.
bool hex_valid(const char* text) {
    if (text == nullptr) {
        return false;
    }
    int length = text.length() as int;
    if (length % 2 != 0) {
        return false;
    }
    for (int index = 0; index < length; index = index + 1) {
        if (hex_digit_value(text[index]) < 0) {
            return false;
        }
    }
    return true;
}

int hex_encode_impl(const char* text, char* output, int output_capacity,
                    bool uppercase) {
    if (text == nullptr || output == nullptr || output_capacity <= 0) {
        return -1;
    }
    int length = text.length() as int;
    int needed = length * 2;
    if (needed + 1 > output_capacity) {
        return -1;
    }
    int source = 0;
    int target = 0;
    while (source < length) {
        int value = (text[source] as uchar) as int;
        output[target] = hex_digit(value / 16, uppercase);
        output[target + 1] = hex_digit(value % 16, uppercase);
        source = source + 1;
        target = target + 2;
    }
    output[needed] = '\0';
    return needed;
}

/// Encode the bytes of `text` as lowercase hexadecimal. The output buffer is
/// NUL-terminated when it fits. Returns the number of characters written, or
/// -1 when the buffer is too small or an argument is null.
int std::encoding::hex_encode(const char* text, char* output,
                              int output_capacity) =>
    hex_encode_impl(text, output, output_capacity, false);

int hex_encode(const char* text, char* output, int output_capacity) =>
    std::encoding::hex_encode(text, output, output_capacity);

/// Uppercase variant of `hex_encode`.
int std::encoding::hex_encode_upper(const char* text, char* output,
                                    int output_capacity) =>
    hex_encode_impl(text, output, output_capacity, true);

int hex_encode_upper(const char* text, char* output, int output_capacity) =>
    std::encoding::hex_encode_upper(text, output, output_capacity);

/// Decode hexadecimal text into bytes. The output is NUL-terminated when it
/// fits. Returns the number of bytes written, or -1 for invalid input, a null
/// argument, or an insufficient buffer.
int std::encoding::hex_decode(const char* text, char* output,
                              int output_capacity) {
    if (text == nullptr || output == nullptr || output_capacity <= 0) {
        return -1;
    }
    int length = text.length() as int;
    if (length % 2 != 0) {
        return -1;
    }
    int needed = length / 2;
    if (needed + 1 > output_capacity) {
        return -1;
    }
    int source = 0;
    int target = 0;
    while (source < length) {
        int high = hex_digit_value(text[source]);
        int low = hex_digit_value(text[source + 1]);
        if (high < 0 || low < 0) {
            return -1;
        }
        output[target] = (high * 16 + low) as char;
        source = source + 2;
        target = target + 1;
    }
    output[needed] = '\0';
    return needed;
}

int hex_decode(const char* text, char* output, int output_capacity) =>
    std::encoding::hex_decode(text, output, output_capacity);
