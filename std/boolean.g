
import std.prelude;

const char* std::to_string(bool b) => switch (b) {
    case true -> "true"
    case false -> "false"
}

const char* to_string(bool b) => std::to_string(b);

