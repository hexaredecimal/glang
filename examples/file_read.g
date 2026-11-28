
import std.io.print: printf;
import std.string.conv;
import std.string.owned;
import std.fs.read;
import std.lib;

void main() {
    auto contentResult = std::fs::read_to_string("main.cpp");
    if (contentResult.is_err()) {
        printf("Failed to read file\n");
        std::exit(1);
    }
    auto content = contentResult.unwrap();
    std::puts(content.c_str());
}

