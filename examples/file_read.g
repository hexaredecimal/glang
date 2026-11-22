
import std.io.print: printf;
import std.string.conv;
import std.fs.read;
import std.memory.owned;
import std.lib;

void main() {
    auto contentResult = std::fs::read_to_string("main.cpp");
    if (contentResult.isErr()) {
        printf("Failed to read file\n");
        std::exit(1);
    }
    auto content = contentResult.unwrap();
    defer std::memory::release(&content);
    std::puts(content.ptr);
}
