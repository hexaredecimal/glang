import std.string.prelude;

[[extern]]
int snprintf(char* buffer, size_t size, const char* format, void*...args);

/// A fixed-capacity, value-type string builder. Copies are independent.
/// Appends that exceed the capacity are truncated.
struct StringBuilder {
    char[2048] data;
    int length;
}

int builder_capacity(StringBuilder builder) => 2048;
int capacity(StringBuilder builder) => 2048;

StringBuilder StringBuilder::new() {
    StringBuilder result;
    result.length = 0;
    result.data[0] = '\0';
    return result;
}

StringBuilder std::string::builder() => StringBuilder::new();

StringBuilder builder_from(const char* text) {
    StringBuilder result = StringBuilder::new();
    if (text == nullptr) {
        return result;
    }
    int index = 0;
    while (text[index] != '\0' && result.length < 2047) {
        result.data[result.length] = text[index];
        result.length = result.length + 1;
        index = index + 1;
    }
    result.data[result.length] = '\0';
    return result;
}

StringBuilder std::string::builder_from(const char* text) => builder_from(text);

StringBuilder builder_append_text(StringBuilder builder, const char* text) {
    if (text == nullptr) {
        return builder;
    }
    int index = 0;
    while (text[index] != '\0' && builder.length < 2047) {
        builder.data[builder.length] = text[index];
        builder.length = builder.length + 1;
        index = index + 1;
    }
    builder.data[builder.length] = '\0';
    return builder;
}

StringBuilder builder_append_char(StringBuilder builder, char value) {
    if (builder.length < 2047) {
        builder.data[builder.length] = value;
        builder.length = builder.length + 1;
        builder.data[builder.length] = '\0';
    }
    return builder;
}

StringBuilder builder_append_int(StringBuilder builder, int value) {
    char[32] buffer;
    snprintf(buffer, 32, "%d", value);
    return builder_append_text(builder, &buffer[0]);
}

StringBuilder builder_append_long(StringBuilder builder, long value) {
    char[32] buffer;
    snprintf(buffer, 32, "%ld", value);
    return builder_append_text(builder, &buffer[0]);
}

StringBuilder builder_append_ulong(StringBuilder builder, ulong value) {
    char[32] buffer;
    snprintf(buffer, 32, "%lu", value);
    return builder_append_text(builder, &buffer[0]);
}

StringBuilder builder_append_double(StringBuilder builder, double value) {
    char[64] buffer;
    snprintf(buffer, 64, "%f", value);
    return builder_append_text(builder, &buffer[0]);
}

StringBuilder builder_append_bool(StringBuilder builder, bool value) {
    if (value) {
        return builder_append_text(builder, "true");
    }
    return builder_append_text(builder, "false");
}

StringBuilder std::string::builder_append_text(StringBuilder builder,
                                               const char* text) =>
    builder_append_text(builder, text);
StringBuilder std::string::builder_append_char(StringBuilder builder,
                                               char value) =>
    builder_append_char(builder, value);
StringBuilder std::string::builder_append_int(StringBuilder builder,
                                              int value) =>
    builder_append_int(builder, value);
StringBuilder std::string::builder_append_double(StringBuilder builder,
                                                 double value) =>
    builder_append_double(builder, value);

/// Remove all contents.
void clear_builder(StringBuilder* builder) {
    builder.length = 0;
    builder.data[0] = '\0';
}

void std::string::clear_builder(StringBuilder* builder) => clear_builder(builder);

const char* builder_c_str(StringBuilder* builder) => &builder.data[0];

const char* std::string::builder_c_str(StringBuilder* builder) =>
    builder_c_str(builder);

const char* builder_to_string(StringBuilder* builder) => &builder.data[0];

const char* std::string::builder_to_string(StringBuilder* builder) =>
    builder_to_string(builder);

int builder_len(StringBuilder builder) => builder.length;
int builder_length(StringBuilder builder) => builder.length;
bool builder_is_empty(StringBuilder builder) => builder.length == 0;

bool std::string::builder_is_empty(StringBuilder builder) =>
    builder_is_empty(builder);


StringBuilder append(StringBuilder builder, const char* text) =>
    builder_append_text(builder, text);
StringBuilder append(StringBuilder builder, char value) =>
    builder_append_char(builder, value);
StringBuilder append(StringBuilder builder, int value) =>
    builder_append_int(builder, value);
StringBuilder append(StringBuilder builder, double value) =>
    builder_append_double(builder, value);
StringBuilder append(StringBuilder builder, bool value) =>
    builder_append_bool(builder, value);

const char* c_str(StringBuilder* builder) => builder_c_str(builder);
const char* to_string(StringBuilder* builder) => builder_to_string(builder);
int len(StringBuilder builder) => builder.length;
int length(StringBuilder builder) => builder.length;
bool is_empty(StringBuilder builder) => builder.length == 0;
void clear(StringBuilder* builder) => clear_builder(builder);


[[infix_operator]]
StringBuilder `<<`(StringBuilder builder, const char* text) =>
    builder_append_text(builder, text);

[[infix_operator]]
StringBuilder `<<`(StringBuilder builder, char value) =>
    builder_append_char(builder, value);

[[infix_operator]]
StringBuilder `<<`(StringBuilder builder, int value) =>
    builder_append_int(builder, value);

[[infix_operator]]
StringBuilder `<<`(StringBuilder builder, double value) =>
    builder_append_double(builder, value);

[[infix_operator]]
StringBuilder `<<`(StringBuilder builder, bool value) =>
    builder_append_bool(builder, value);
