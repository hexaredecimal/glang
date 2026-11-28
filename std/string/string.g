import std.string.len;
import std.memory.rc;
import std.memory.c.mem;

// The small-buffer size. `capacity` counts usable characters and excludes the
// terminating NUL, so a 256-byte inline buffer holds at most 255 characters.
const int std::string::SSO_CAPACITY = 40;

/// A growable, NUL-terminated UTF-8/byte string with small-string
/// optimization.
///
/// Up to 39 bytes live inline in `sso`. Longer strings use `buffer`, which is
/// reference counted by `Box<char>`. Copies are cheap and use copy-on-write:
/// any operation that mutates a shared heap buffer first detaches it, so value
/// copies never observe each other's writes.
struct String {
    char[40] sso;
    Box<char> buffer;
    uint capacity;
    uint length;
}

/// Create an empty string.
String String::new() {
    String result;
    result.capacity = std::string::SSO_CAPACITY as uint;
    result.length = 0;
    result.sso[0] = '\0';
    return result;
}

/// Create a string with room for at least `capacity` characters.
String String::with_capacity(int capacity) {
    String result = String::new();
    if (capacity > std::string::SSO_CAPACITY) {
        result.buffer = Box<char>::array((capacity as ulong) + 1);
        result.capacity = capacity as uint;
    }
    return result;
}

/// Copy the NUL-terminated text `str` into a new string. A null pointer yields
/// the empty string.
String String::from(const char* str) {
    if (str == nullptr) {
        return String::new();
    }
    return String::from(str, std::string::length(str));
}

/// Copy at most `count` characters of `str` into a new string. A null pointer
/// yields the empty string.
String String::from(const char* str, ulong count) {
    if (str == nullptr) {
        return String::new();
    }
    ulong actual = 0;
    while (actual < count && str[actual] != '\0') {
        actual = actual + 1;
    }
    String result = String::with_capacity(actual as int);
    char* destination = result.data();
    std::memory::memcpy(destination, str, actual);
    /*
    ulong index = 0;
    while (index < actual) {
        destination[index] = str[index];
        index = index + 1;
    }*/
    destination[actual as int] = '\0';
    result.length = actual as uint;
    return result;
}

/// Number of characters, excluding the terminating NUL.
int String::size(String* self) => self.length as int;

/// Alias for `size`.
int String::len(String* self) => self.length as int;

/// True when the string contains no characters.
bool String::is_empty(String* self) => self.length == 0;

/// NUL-terminated read-only view of the text. The pointer is valid while this
/// string is alive and is invalidated by mutation or growth.
const char* String::c_str(String* self) {
    if (self.buffer == nullptr) {
        return self.sso;
    }
    return &(*self.buffer);
}

/// Split the heap buffer when more than one `String` shares it, so mutations
/// never leak into value copies.
void String::detach(String* self) {
    if (self.buffer == nullptr) {
        return;
    }
    if (use_count(&self.buffer) <= 1) {
        return;
    }
    Box<char> copy = Box<char>::array((self.capacity as ulong) + 1);
    const char* source = &(*self.buffer);
    char* destination = &(*copy);
    std::memory::memcpy(destination, source, self.length);
    self.buffer = copy;
}

/// Mutable NUL-terminated view of the text. Detaches a shared buffer first.
char* String::data(String* self) {
    String::detach(self);
    if (self.buffer == nullptr) {
        return self.sso;
    }
    return &(*self.buffer);
}

/// Ensure the string can hold at least `capacity` characters without growing.
void String::reserve(String* self, int capacity) {
    if (capacity <= std::string::SSO_CAPACITY && self.buffer == nullptr) {
        self.capacity = std::string::SSO_CAPACITY as uint;
        if (self.length == 0) {
            self.sso[0] = '\0';
        }
        return;
    }
    if (capacity <= self.capacity as int) {
        return;
    }
    // "Reserve".println();
    int next = self.capacity as int;
    if (next < 16) {
        next = 16;
    }
    while (next < capacity) {
        if (next > 1073741824) {
            next = capacity;
            break;
        }
        next = next * 2;
    }
    Box<char> nextStorage = Box<char>::array((next as ulong) + 1);
    const char* source = String::c_str(self);
    char* destination = &(*nextStorage);
    uint index = 0;
    /*while (index < self.length) {
        destination[index] = source[index];
        index = index + 1;
    }*/
    std::memory::memcpy(destination, source, self.length);
    destination[self.length] = '\0';
    std::memory::memset(self.sso, 0, self.sso.length);
    self.buffer = nextStorage;
    self.capacity = next as uint;
}

/// Append one character.
void String::push(String* self, char value) {
    if (self.capacity == 0 && self.buffer == nullptr) {
        self.capacity = std::string::SSO_CAPACITY as uint;
        self.sso[0] = '\0';
    }
    if (self.length >= self.capacity) {
        int next = 16;
        if (self.capacity > 0) {
            next = (self.capacity as int) * 2;
        }
        String::reserve(self, next);
    }
    char* buffer = String::data(self);
    buffer[self.length] = value;
    self.length = self.length + 1;
    buffer[self.length] = '\0';
}

/// Append a NUL-terminated string.
void String::push(String* self, const char* value) {
    if (value == nullptr) {
        return;
    }
    String::push(self, value, std::string::length(value));
}

/// Append at most `count` characters of `value`.
void String::push(String* self, const char* value, ulong count) {
    if (value == nullptr || count == 0) {
        return;
    }
    ulong actual = 0;
    while (actual < count && value[actual] != '\0') {
        actual = actual + 1;
    }
    if (actual == 0) {
        return;
    }
    if (self.capacity == 0 && self.buffer == nullptr) {
        self.capacity = std::string::SSO_CAPACITY as uint;
        self.sso[0] = '\0';
    }
    uint required = self.length + (actual as uint);
    if (required > self.capacity) {
        String::reserve(self, required as int);
    }
    char* buffer = String::data(self);
    uint offset = 0;
    while (offset < (actual as uint)) {
        buffer[self.length + offset] = value[offset];
        offset = offset + 1;
    }
    self.length = required;
    buffer[self.length] = '\0';
}

/// Alias for `push`.
void String::append(String* self, char value) => String::push(self, value);
void String::append(String* self, const char* value) =>
    String::push(self, value);
void String::append(String* self, const char* value, ulong count) =>
    String::push(self, value, count);

/// Remove every character while keeping the current capacity.
void String::clear(String* self) {
    if (self.capacity == 0 && self.buffer == nullptr) {
        self.capacity = std::string::SSO_CAPACITY as uint;
    }
    char* buffer = String::data(self);
    self.length = 0;
    buffer[0] = '\0';
}

/// Deep-copy the text into independent storage.
String String::clone(String* self) {
    String result = String::with_capacity(self.length as int);
    char* destination = result.data();
    const char* source = String::c_str(self);
    uint index = 0;
    while (index < self.length) {
        destination[index] = source[index];
        index = index + 1;
    }
    destination[self.length] = '\0';
    result.length = self.length;
    return result;
}

/// True when this string and `other` contain the same bytes.
bool String::equals(String* self, const char* other) {
    if (other == nullptr) {
        return self.length == 0;
    }
    const char* text = String::c_str(self);
    uint index = 0;
    while (index < self.length && other[index] != '\0') {
        if (text[index] != other[index]) {
            return false;
        }
        index = index + 1;
    }
    return index == self.length && other[index] == '\0';
}

/// Lexicographic comparison with `other`: -1, 0, or 1.
int String::compare(String* self, const char* other) {
    const char* text = String::c_str(self);
    if (other == nullptr) {
        if (self.length == 0) {
            return 0;
        }
        return 1;
    }
    uint index = 0;
    while (index < self.length && other[index] != '\0') {
        if (text[index] < other[index]) {
            return -1;
        }
        if (text[index] > other[index]) {
            return 1;
        }
        index = index + 1;
    }
    if (index == self.length && other[index] == '\0') {
        return 0;
    }
    if (index == self.length) {
        return -1;
    }
    return 1;
}

// Namespaced and free-function forms keep every operation available through
// UFCS and through `std::string::...` calls.

const char* std::string::c_str(String* self) => String::c_str(self);
char* std::string::data(String* self) => String::data(self);

const char* c_str(String* self) => String::c_str(self);
char* data(String* self) => String::data(self);
int size(String* self) => String::size(self);
int len(String* self) => String::len(self);
bool is_empty(String* self) => String::is_empty(self);
void reserve(String* self, int capacity) => String::reserve(self, capacity);
void push(String* self, char value) => String::push(self, value);
void push(String* self, const char* value) => String::push(self, value);
void push(String* self, const char* value, ulong count) =>
    String::push(self, value, count);
void append(String* self, char value) => String::append(self, value);
void append(String* self, const char* value) => String::append(self, value);
void clear(String* self) => String::clear(self);
String clone(String* self) => String::clone(self);
bool equals(String* self, const char* other) => String::equals(self, other);
int compare(String* self, const char* other) => String::compare(self, other);

/// Convert a C string into an independent `String`.
String to_string(const char* str) => String::from(str);
String to_string(const char* str, ulong count) => String::from(str, count);

/// Convert a C string into an independent `String`.
String to_owned(const char* str) => String::from(str);
String to_owned(const char* str, ulong count) => String::from(str, count);

/// Concatenate two strings into a new string.
String concat(String left, String right) {
    String result = String::with_capacity((left.length + right.length) as int);
    result.push(left.c_str());
    result.push(right.c_str());
    return result;
}

/// Concatenate a string and a C string into a new string.
String concat(String left, const char* right) {
    String result = String::with_capacity(
        (left.length + std::string::length(right)) as int);
    result.push(left.c_str());
    result.push(right);
    return result;
}

[[infix_operator]]
String `+`(String left, String right) => concat(left, right);

[[infix_operator]]
String `+`(String left, const char* right) => concat(left, right);

[[infix_operator]]
String `+`(const char* left, String right) =>
    concat(String::from(left), right);


[[infix_operator]]
String `+`(const char* left, const char* right) {
    auto lhs = String::from(left);
    auto rhs = String::from(right);
    return lhs + rhs;
}

[[infix_operator]]
bool `==`(String left, const char* right) => left.equals(right);

[[infix_operator]]
bool `==`(const char* left, String right) => right.equals(left);

[[infix_operator]]
bool `!=`(String left, String right) => !left.equals(right.c_str());

[[infix_operator]]
bool `!=`(String left, const char* right) => !left.equals(right);

[[infix_operator]]
bool `!=`(const char* left, String right) => !right.equals(left);
