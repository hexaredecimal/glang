import std.chars.types;
import std.string.string;
import std.string.len;

/// Copy of `s` with every character converted to upper case. The input is
/// not modified.
String std::string::to_upper(const char* s) {
    auto result = String::from(s);
    char* text = result.data();
    int len = result.size();
    for (int i = 0; i < len; ++i) {
        text[i] = (text[i] as uchar).to_upper();
    }
    return result;
}

/// Copy of `s` with every character converted to lower case. The input is
/// not modified.
String std::string::to_lower(const char* s) {
    auto result = String::from(s);
    char* text = result.data();
    int len = result.size();
    for (int i = 0; i < len; ++i) {
        text[i] = (text[i] as uchar).to_lower();
    }
    return result;
}

/// String-receiver forms.
String String::to_upper(String* self) =>
    std::string::to_upper(String::c_str(self));
String String::to_lower(String* self) =>
    std::string::to_lower(String::c_str(self));

String to_lower(const char* s) => std::string::to_lower(s);
String to_upper(const char* s) => std::string::to_upper(s);
