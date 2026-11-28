
import std.memory.c.alloc;
import std.fs.file;
import std.fs.prelude;
import std.result;
import std.string.string;

/// Read an entire file into a `String`. The result owns its storage and is
/// released automatically when the last copy is dropped.
Result<String> std::fs::read_to_string(const char* path) {
    File* fp = path.fopen("rb");
    if (!fp) {
        return std::error("std::fs::read_to_string: Failed to open file");
    }
    defer fp.fclose();

    long size = fp.get_size();
    if (size < 0) {
        return std::error("std::fs::read_to_string: Failed to determine file size");
    }

    auto (buffer, isOk) = std::memory::allocate<char>((size + 1) as ulong);
    if (!isOk) {
        return std::error("std::fs::read_to_string: Failed to allocate memory");
    }

    size_t read_count = fread(buffer, 1, size as size_t, fp);
    if (read_count != size as size_t) {
        std::memory::free_raw(buffer);
        return std::error("std::fs::read_to_string: Failed to read entire file");
    }
    buffer[size as int] = '\0';
    String text = String::from(buffer, size as ulong);
    std::memory::free_raw(buffer);
    return std::ok(text);
}
