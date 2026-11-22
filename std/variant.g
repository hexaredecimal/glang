
import std.prelude

enum std::VariantKind {
    Some,
    None,
    Ok, 
    Err
}

type VariantResultCallback<T> = T (*f)();
