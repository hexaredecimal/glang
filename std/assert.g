import std.prelude;
import std.lib;
import std.io.print;

void assert(bool condition, const char* message) {
    if (!condition) {
        printf("Assertion failed: %s\n", message);
        std::abort();
    }
}

void assert(bool condition) => assert(condition, "Assertion failed");

void std::assert(bool condition, const char* message) => assert(condition, message);
void std::assert(bool condition) => assert(condition);
