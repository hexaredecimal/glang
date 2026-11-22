

import std.chars.types;
import std.string.dup;

void std::string::to_upper(char* s) {
    auto len = s.strlen();
    for (int i = 0; i < len; ++i) {
        s[i] = (s[i] as uchar).to_upper();
    }
}

void std::string::to_lower(char* s) {
    auto len = s.strlen();
    for (int i = 0; i < len; ++i) {
        s[i] =(s[i] as uchar).to_lower();
    }
}

void to_lower(char* s) => std::string::to_lower(s);
void to_upper(char* s) => std::string::to_upper(s);