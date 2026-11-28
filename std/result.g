import std.variant;
import std.panic;

struct IResultU<T, E> {
    T value;
    E error;
}

struct std::Result<T, E> {
    type ResultType = T;
    type ErrorType = E; 

    std::VariantKind kind;
    IResultU<T, E> u;
}

std::Result<T, E> create_result<T, E>(std::VariantKind kind) {
    std::Result<T, E> r;
    r.kind = kind;
    return r;
}

type Result<T> = std::Result<T, const char*>; 

Result<T> std::ok<T>(T v) {
    auto r = create_result<T, const char*>(std::VariantKind::Ok);
    r.u.value = v;
    return r;
}

Result<T> std::error<T>(const char* v) {
    auto r =  create_result<T, const char*>(std::VariantKind::Err);
    r.u.error = v;
    return r;
}

T unwrap<T>(Result<T> opt) {
    if (opt.kind == std::VariantKind::Err) {
        std::panic("Attempt to unwrap a result of std::error<T>()");
    }
    return opt.u.value;
}

T unwrap_or<T>(Result<T> opt, T def) {
    if (opt.kind == std::VariantKind::Err) {
        return def;
    }
    return opt.u.value;
}

T unwrap_or<T>(Result<T> opt, VariantResultCallback<T> f) {
    if (opt.kind == std::VariantKind::Err) {
        return f();
    }
    return opt.u.value;
}

(T, bool)  unwrap_safe<T>(Result<T> opt) {
    if (opt.kind == std::VariantKind::Err) {
        T def;
        return (def, false);
    }
    return (opt.u.value, true);
}

const char* unwrap_err<T>(Result<T> opt) {
    if (opt.kind != std::VariantKind::Err) {
        std::panic("Attempt to unwrap a result of std::error<T>()");
    }
    return opt.u.error;
}

const char* unwrap_err_or<T>(Result<T> opt, T def) {
    if (opt.kind == std::VariantKind::Err) {
        return def;
    }
    return opt.u.error;
}

const char* unwrap_err_or<T>(Result<T> opt, VariantResultCallback<T> f) {
    if (opt.kind == std::VariantKind::Err) {
        return f();
    }
    return opt.u.error;
}

(const char*, bool)  unwrap_err_safe<T>(Result<T> opt) {
    if (opt.kind == std::VariantKind::Err) {
        return (nullptr, false);
    }
    return (opt.u.error, true);
}

bool is_ok<T>(Result<T> r) => r.kind == std::VariantKind::Ok;
bool is_error<T>(Result<T> r) => r.kind == std::VariantKind::Err;

[[postfix_operator]]
T `?`<T>(Result<T> res) => res.unwrap(); 

[[infix_operator]]
T `??`<T>(Result<T> res, T def) => res.unwrap_or(def); 
