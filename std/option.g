
import std.lib; 
import std.variant;
import std.panic;

struct std::Option<T> {
    std::VariantKind kind;
    T value;
}

type Option<T> = std::Option<T>;

std::Option<T> std::some<T>(T value) => std::Option{std::VariantKind::Some, value};
std::Option<T> std::none<T>() {
    T def;
    return std::Option{std::VariantKind::None, def};
}


T unwrap<T>(std::Option<T> opt) {
    if (opt.kind == std::VariantKind::None) {
        std::panic("Attempt to unwrap a result of std::none<T>()");
    }
    return opt.value;
}

T unwrap_or<T>(std::Option<T> opt, T def) {
    if (opt.kind == std::VariantKind::None) {
        return def;
    }
    return opt.value;
}

T unwrap_or<T>(std::Option<T> opt, VariantResultCallback<T> f) {
    if (opt.kind == std::VariantKind::None) {
        return f();
    }
    return opt.value;
}

bool is_some<T>(std::Option<T> opt) => opt.kind == std::VariantKind::Some;
bool is_none<T>(std::Option<T> opt) => opt.kind == std::VariantKind::None;


(T, bool)  unwrap_safe<T>(std::Option<T> opt) {
    if (opt.kind == std::VariantKind::None) {
        T def;
        return (def, false);
    }
    return (opt.value, true);
}

[[postfix_operator]]
T `?`<T>(std::Option<T> res) => res.unwrap(); 

[[infix_operator]]
T `??`<T>(std::Option<T> res, T def) => res.unwrap_or(def); 
