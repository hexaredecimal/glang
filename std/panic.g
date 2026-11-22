
import std.lib;
import std.io.print; 


/// Prints a message to the console and aborts
void std::panic(const char* message) {
    if (message) {
        printf("std::panic: %s", message);
    }
    std::abort();
}

