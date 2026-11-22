import std.fs.stds;
import std.prelude;

[[extern, c_abi]]
int fputs(const char* text, File* stream);

[[extern]]
int fprintf(File* stream, const char* format, void*...args);

/// Write a string to standard error without a trailing newline.
void eprint(const char* text) {
    fputs(text, File::StdErr);
}

/// Write a string to standard error followed by a newline.
void eprintln(const char* text) {
    fputs(text, File::StdErr);
    fputs("\n", File::StdErr);
}

void eprintln(int value) { fprintf(File::StdErr, "%d\n", value); }
void eprintln(double value) { fprintf(File::StdErr, "%f\n", value); }
void eprintln(bool value) {
    if (value) {
        eprintln("true");
    } else {
        eprintln("false");
    }
}

void std::eprint(const char* text) => eprint(text);
void std::eprintln(const char* text) => eprintln(text);
void std::eprintln(int value) => eprintln(value);
void std::eprintln(double value) => eprintln(value);
void std::eprintln(bool value) => eprintln(value);
