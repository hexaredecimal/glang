
import std.prelude;

const char* std::to_c_str(bool b) => switch (b) {
    case true -> "true"
    case false -> "false"
}

const char* c_str(bool b) => char* std::c_str(b);

