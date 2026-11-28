import std.fs.prelude;
import std.string.search;
import std.string.len;

/// A fixed-capacity, value-type filesystem path. Paths longer than the
/// capacity are truncated. Copying a Path copies its buffer.
struct Path {
    char[1024] data;
    int length;
}

/// Construct a Path from a C string. `null` produces an empty path.
Path Path::new(const char* text) {
    Path result;
    result.length = 0;
    result.data[0] = '\0';
    if (text == nullptr) {
        return result;
    }
    int index = 0;
    while (text[index] != '\0' && index < 1023) {
        result.data[index] = text[index];
        index = index + 1;
    }
    result.data[index] = '\0';
    result.length = index;
    return result;
}

Path std::fs::make_path(const char* text) => Path::new(text);
Path std::fs::to_path(const char* text) => Path::new(text);

/// Pointer to the Path's NUL-terminated buffer. The pointer is valid while
/// the Path value remains alive and unmodified.
const char* path_c_str(Path* path) => &path.data[0];

const char* c_str(Path* path) => path_c_str(path);
const char* std::fs::c_str(Path* path) => path_c_str(path);

int path_length(Path path) => path.length;
int len(Path path) => path.length;
int length(Path path) => path.length;

bool path_is_empty(Path path) => path.length == 0;
bool is_empty(Path path) => path.length == 0;

bool path_ends_with_separator(Path path) {
    if (path.length == 0) {
        return false;
    }
    char last = path.data[path.length - 1];
    return last == '/' || last == '\\';
}

bool path_starts_with_separator(const char* text) {
    if (text == nullptr || text[0] == '\0') {
        return false;
    }
    return text[0] == '/' || text[0] == '\\';
}

/// Append `text` without inserting a separator.
Path append_path(Path path, const char* text) {
    if (text == nullptr) {
        return path;
    }
    int index = 0;
    while (text[index] != '\0' && path.length < 1023) {
        path.data[path.length] = text[index];
        path.length = path.length + 1;
        index = index + 1;
    }
    path.data[path.length] = '\0';
    return path;
}

Path std::fs::append_path(Path path, const char* text) => append_path(path, text);

/// Join two path components with a single separator. A separator is omitted
/// when the left side already ends with one or the right side starts with one.
Path join_path(const char* left, const char* right) {
    Path result = Path::new(left);
    if (right == nullptr || right[0] == '\0') {
        return result;
    }
    bool needSeparator =
        result.length > 0 && !path_ends_with_separator(result) &&
        !path_starts_with_separator(right);
    if (needSeparator) {
        result.data[result.length] = '/';
        result.length = result.length + 1;
    }
    return append_path(result, right);
}

Path std::fs::join_path(const char* left, const char* right) => join_path(left, right);

/// Remove the last component. Roots such as "/" and "C:/" are preserved.
Path parent_path(Path path) {
    int end = path.length - 1;
    while (end >= 0 &&
           (path.data[end] == '/' || path.data[end] == '\\')) {
        end = end - 1;
    }
    int split = end;
    while (split >= 0 && path.data[split] != '/' && path.data[split] != '\\') {
        split = split - 1;
    }
    if (split < 0) {
        if (path.length >= 2 && path.data[1] == ':') {
            path.length = 2;
            path.data[2] = '\0';
        } else {
            path.length = 0;
            path.data[0] = '\0';
        }
        return path;
    }
    if (split == 0) {
        path.length = 1;
        path.data[1] = '\0';
        return path;
    }
    if (split == 2 && path.data[1] == ':') {
        path.length = 3;
        path.data[3] = '\0';
        return path;
    }
    path.length = split;
    path.data[split] = '\0';
    return path;
}

Path std::fs::parent_path(Path path) => parent_path(path);
Path parent(Path path) => parent_path(path);

/// Collapse repeated separators and convert backslashes to forward slashes.
Path normalize_path(Path path) {
    int readIndex = 0;
    int writeIndex = 0;
    while (readIndex < path.length) {
        char current = path.data[readIndex];
        if (current == '\\') {
            current = '/';
        }
        if (current == '/' && writeIndex > 0 &&
            path.data[writeIndex - 1] == '/') {
            readIndex = readIndex + 1;
            continue;
        }
        path.data[writeIndex] = current;
        writeIndex = writeIndex + 1;
        readIndex = readIndex + 1;
    }
    path.length = writeIndex;
    path.data[writeIndex] = '\0';
    return path;
}

Path std::fs::normalize_path(Path path) => normalize_path(path);
Path normalize(Path path) => normalize_path(path);

/// True for "/root", "\\server", or "C:..." style paths.
bool path_is_absolute(Path path) {
    if (path.length == 0) {
        return false;
    }
    if (path.data[0] == '/' || path.data[0] == '\\') {
        return true;
    }
    return path.length >= 2 && path.data[1] == ':';
}

bool std::fs::is_absolute(Path path) => path_is_absolute(path);
bool is_absolute(Path path) => path_is_absolute(path);

/// Replace the extension of the final component. `extension` may include the
/// leading dot or omit it; an empty extension removes the existing suffix.
Path with_extension(Path path, const char* extension) {
    int nameStart = path.length - 1;
    while (nameStart >= 0 && path.data[nameStart] != '/' &&
           path.data[nameStart] != '\\') {
        nameStart = nameStart - 1;
    }
    nameStart = nameStart + 1;

    int dot = -1;
    for (int index = nameStart; index < path.length; index = index + 1) {
        if (path.data[index] == '.') {
            dot = index;
        }
    }
    if (dot > nameStart) {
        path.length = dot;
        path.data[dot] = '\0';
    }

    if (extension == nullptr || extension[0] == '\0') {
        return path;
    }
    if (extension[0] != '.') {
        path = append_path(path, ".");
    }
    return append_path(path, extension);
}

Path std::fs::with_extension(Path path, const char* extension) =>
    with_extension(path, extension);

/// Final component of a Path. The returned pointer aliases the Path buffer.
const char* path_file_name(Path* path) => std::fs::file_name(path_c_str(path));

const char* path_extension(Path* path) => std::fs::extension(path_c_str(path));

bool path_has_extension(Path* path, const char* extension) =>
    std::fs::has_extension(path_c_str(path), extension);

const char* file_name(Path* path) => path_file_name(path);
const char* extension(Path* path) => path_extension(path);
bool has_extension(Path* path, const char* extension) =>
    path_has_extension(path, extension);

// Path composition: `"C:" / "Users" / "name"`.

[[infix_operator]]
Path `/`(const char* left, const char* right) => join_path(left, right);

[[infix_operator]]
Path `/`(Path left, const char* right) => join_path(path_c_str(&left), right);

[[infix_operator]]
Path `/`(const char* left, Path right) => join_path(left, path_c_str(&right));

[[infix_operator]]
Path `/`(Path left, Path right) =>
    join_path(path_c_str(&left), path_c_str(&right));

// Path suffix concatenation without an implicit separator.

[[infix_operator]]
Path `+`(Path left, const char* suffix) => append_path(left, suffix);

[[infix_operator]]
Path `+`(Path left, Path suffix) =>
    append_path(left, path_c_str(&suffix));

/// Final component of a path. The result points into `path`; it is not a
/// newly allocated string.
const char* std::fs::file_name(const char* path) {
    if (path == nullptr) {
        return "";
    }
    int lastSeparator = -1;
    int index = 0;
    while (path[index] != '\0') {
        if (path[index] == '/' || path[index] == '\\') {
            lastSeparator = index;
        }
        index = index + 1;
    }
    if (lastSeparator < 0) {
        return path;
    }
    return path + lastSeparator + 1;
}

/// Extension including the leading dot, or an empty string when absent.
/// The result points into `path`.
const char* std::fs::extension(const char* path) {
    const char* name = std::fs::file_name(path);
    int lastDot = -1;
    int index = 0;
    while (name[index] != '\0') {
        if (name[index] == '.') {
            lastDot = index;
        }
        index = index + 1;
    }
    if (lastDot < 0 || lastDot == 0) {
        return "";
    }
    return name + lastDot;
}

/// True when `path` ends with `extension` (including the leading dot).
bool std::fs::has_extension(const char* path, const char* extension) {
    const char* actual = std::fs::extension(path);
    return std::string::equals(actual, extension);
}

const char* file_name(const char* path) => std::fs::file_name(path);
const char* extension(const char* path) => std::fs::extension(path);
bool has_extension(const char* path, const char* extension) =>
    std::fs::has_extension(path, extension);
Path to_path(const char* text) => Path::new(text);
