import std.prelude;

[[infix_operator]]
R `|>` <T, R>(T value, R (*fn)(T)) => fn(value);
