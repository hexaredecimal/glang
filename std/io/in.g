
import std.fs.stds;
import std.string.conv;
import std.string.string;

[[extern]]
int scanf(const char* fmt, void* ...);

[[extern]]
int getc(File* fp);

[[extern]]
int getchar();

struct StdinData {
    char[4096] buffer;
}
// TODO: Wrap this in Result<T> to handle the error cases
// TODO:  Note that scanf returns result <= 0 when an error happend
// TODO: Rewrite this function to be safe and use String instead of a fixed buffer.
StdinData readIn(const char* message) {
    message.print();
    auto out = StdinData{};
    scanf(" %4095[^\n]", &out.buffer);
    return out;
}

double to_double(StdinData* data) => (&data.buffer[0]).to_double();
float to_float(StdinData* data) => (&data.buffer[0]).to_double() as float;
long to_long(StdinData* data) => (&data.buffer[0]).to_long();
int to_int(StdinData* data) => (&data.buffer[0]).to_int();
String to_string(StdinData* data) => String::from(data.buffer, data.buffer.length);
