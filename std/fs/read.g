

import std.memory.c.alloc;
import std.memory.owned;
import std.fs.file;
import std.fs.prelude;
import std.result;

Result<std::memory::Owned<char>> std::fs::read_to_string(const char* path) {
    File* fp = path.fopen("rb");
    if (!fp) {
        return std::error("std::fs::read_to_string: Failed to open file");
    }
    defer fp.fclose();

    long size = fp.get_size();
    if (size < 0) {
      return std::error("std::fs::read_to_string: Failed to determine file size");
    }

    auto (buffer, isOk) = std::memory::allocate<char>(size + 1);
    if (!isOk) {
      return std::error("std::fs::read_to_string: Failed to allocate memory");
    }

    size_t read_count = fread(buffer, 1, size, fp);
    if (read_count != size) {
      buffer.free();
      return std::error("std::fs::read_to_string: Failed to read entire file");
    }
    buffer[size] = '\0';
    return std::ok(std::memory::Owned{buffer, (size + 1) as size_t});
}