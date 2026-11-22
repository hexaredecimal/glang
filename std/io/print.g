import std.prelude;

[[extern]]
int printf(const char* fmt, void*...args);

[[extern]]
int puts(const char* str);

int std::puts(const char* s) => s.puts();

void print(const char* s) { printf("%s", s); }
void println(const char* s) { printf("%s\n", s); }
void print(int val) { printf("%d", val); }
void println(int val) { printf("%d\n", val); }
void print(long val) { printf("%ld", val); }
void println(long val) { printf("%ld\n", val); }
void print(double val) { printf("%f", val); }
void println(double val) { printf("%f\n", val); }
void print(bool val) {
    if (val) {
        printf("true");
    } else {
        printf("false");
    }
}
void println(bool val) {
    if (val) {
        printf("true\n");
    } else {
        printf("false\n");
    }
}

void print(char val) { printf("%c", val as int); }
void println(char val) { printf("%c\n", val as int); }
void print(uchar val) { printf("%u", val as uint); }
void println(uchar val) { printf("%u\n", val as uint); }
void print(short val) { printf("%d", val as int); }
void println(short val) { printf("%d\n", val as int); }
void print(ushort val) { printf("%u", val as uint); }
void println(ushort val) { printf("%u\n", val as uint); }
void print(uint val) { printf("%u", val); }
void println(uint val) { printf("%u\n", val); }
void print(ulong val) { printf("%lu", val); }
void println(ulong val) { printf("%lu\n", val); }
void print(float val) { printf("%f", val as double); }
void println(float val) { printf("%f\n", val as double); }
void print(void* val) { printf("%p", val); }
void println(void* val) { printf("%p\n", val); }
void println() { printf("\n"); }

void std::print(const char* s) => print(s);
void std::println(const char* s) => println(s);
void std::print(int val) => print(val);
void std::println(int val) => println(val);
void std::print(double val) => print(val);
void std::println(double val) => println(val);
void std::print(bool val) => print(val);
void std::println(bool val) => println(val);
void std::print(char val) => print(val);
void std::println(char val) => println(val);
void std::print(uchar val) => print(val);
void std::println(uchar val) => println(val);
void std::print(short val) => print(val);
void std::println(short val) => println(val);
void std::print(ushort val) => print(val);
void std::println(ushort val) => println(val);
void std::print(uint val) => print(val);
void std::println(uint val) => println(val);
void std::print(ulong val) => print(val);
void std::println(ulong val) => println(val);
void std::print(float val) => print(val);
void std::println(float val) => println(val);
void std::print(void* val) => print(val);
void std::println(void* val) => println(val);
void std::println() => println();
