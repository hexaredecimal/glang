import std.fs.file;
import std.fs.prelude;
import std.string.len;
import std.result;

Result<bool> std::fs::write_string(const char* path, const char* text) {
    auto (file, opened) = std::file::open(path, "wb");
    if (!opened || file == nullptr) {
        return std::error("std::fs::write_string: Failed to open file");
    }
    defer fclose(file);

    size_t length = text.length();
    size_t written = fwrite(text, 1, length, file);
    if (written != length) {
        return std::error("std::fs::write_string: Failed to write entire file");
    }
    return std::ok(true);
}

Result<bool> std::fs::append_string(const char* path, const char* text) {
    auto (file, opened) = std::file::open(path, "ab");
    if (!opened || file == nullptr) {
        return std::error("std::fs::append_string: Failed to open file");
    }
    defer fclose(file);

    size_t length = text.length();
    size_t written = fwrite(text, 1, length, file);
    if (written != length) {
        return std::error("std::fs::append_string: Failed to write entire file");
    }
    return std::ok(true);
}

Result<bool> std::fs::write_bytes(const char* path, const void* data, size_t count) {
    auto (file, opened) = std::file::open(path, "wb");
    if (!opened || file == nullptr) {
        return std::error("std::fs::write_bytes: Failed to open file");
    }
    defer fclose(file);

    size_t written = fwrite(data, 1, count, file);
    if (written != count) {
        return std::error("std::fs::write_bytes: Failed to write entire file");
    }
    return std::ok(true);
}

Result<bool> write_string(const char* path, const char* text) => std::fs::write_string(path, text);
Result<bool> append_string(const char* path, const char* text) => std::fs::append_string(path, text);
Result<bool> write_bytes(const char* path, const void* data, size_t count) => std::fs::write_bytes(path, data, count);
