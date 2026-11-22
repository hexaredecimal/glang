# Glang Language Specification

**Status:** implementation specification for the compiler in this repository.  
**Backend:** generated C++ (currently tested with a modern `g++`).  
**Conformance note:** Glang is experimental. This document distinguishes behavior the compiler intends to provide from behavior inherited from C++ or not yet guaranteed. The numbered tests under `tests/` are executable examples, not a complete conformance suite.

## 1. Translation and execution model

A Glang source file is lexed and parsed into an AST, type-checked with imported source modules, translated to C++, then optionally compiled and linked by the command-line driver. A successful type check does not guarantee that the generated C++ is accepted by every compiler or platform. Native object layout, integer widths, calling conventions, standard-library behavior, and undefined behavior follow the target C++ implementation.

Imports identify source modules using dotted names (`std.fs.read`). The compiler resolves and checks imported modules as part of the compilation. Selective imports use a colon (`import std.io.print: printf, puts;`). Imports do not install native dependencies or supply arbitrary C/C++ headers. Prefix, infix, and postfix operators declared in an imported module are available in the importing file without redeclaration. Operators are always imported wholesale, including when a selective symbol list is present, because an operator spelling cannot appear in that list.

## 2. Lexical elements

Identifiers begin with an ASCII letter or underscore and continue with letters, digits, or underscores. Whitespace is insignificant except where it separates tokens. `//` starts a line comment; `/* ... */` starts a block comment. Documentation comments are collected for language tooling.

Integer and floating-point literals may contain underscores. String literals use double quotes and character literals use single quotes. The lexer decodes C-style escapes including newline, tab, carriage return, slash, quotes, control escapes, octal byte escapes, hexadecimal byte escapes, and NUL (`\0`). The C++ backend re-escapes the decoded bytes. Strings are byte strings with C-string behavior in standard C APIs; an embedded NUL terminates such API operations. A character is one target `char` byte, not a Unicode scalar value.

The lexer recognizes the following keywords: `import`, `struct`, `union`, `enum`, `type`, `const`, `static`, `auto`, `void`, `bool`, `char`, `uchar`, `short`, `ushort`, `int`, `uint`, `long`, `ulong`, `float`, `double`, `if`, `else`, `switch`, `case`, `default`, `yield`, `return`, `while`, `do`, `for`, `break`, `continue`, `defer`, `as`, `sizeof`, `true`, `false`, and `nullptr`.

Attributes are written as `[name]` or `[[name, other]]`. Implemented uses include `extern`, `c_abi`, `core`, `private`, `userLiteral`, and `no_custom_operators`. Attributes are compiler metadata, not a general macro facility.

## 3. Declarations and types

The following grammar is schematic EBNF. It omits documentation text and error-recovery productions; `identifier` and `expression` refer to their normal lexical and syntactic forms.

```ebnf
program          = { import | declaration | top_level_statement } ;
module_path      = identifier { "." identifier } ;
import           = "import" module_path [ ":" identifier { "," identifier } ]
                   { "," module_path [ ":" identifier { "," identifier } ] }
                   [ ";" ] ;
declaration      = { attribute } ( struct_decl | union_decl | enum_decl
                   | type_alias | function_decl ) ;
attribute        = "[" attribute_list "]" | "[[" attribute_list "]]" ;
attribute_list   = attribute_item { "," attribute_item } ;
attribute_item   = identifier [ "(" [ expression { "," expression } ] ")" ] ;
struct_decl      = "struct" qualified_name [ type_parameters ] "{"
                   { field | associated_alias } "}" ;
union_decl       = "union" qualified_name [ type_parameters ] "{"
                   { field } "}" ;
enum_decl        = "enum" qualified_name "{"
                   { identifier [ "," | ";" ] } "}" ;
field            = type identifier ";" ;
associated_alias = "type" identifier "=" type [ ";" ] ;
type_alias       = "type" identifier [ type_parameters ] "=" type [ ";" ] ;
function_decl    = type qualified_name [ type_parameters ] "(" parameters ")"
                   ( block | "=>" expression [ ";" ] | ";" ) ;
operator_decl    = { attribute } type operator_symbol [ type_parameters ]
                   "(" parameters ")" ( block | "=>" expression [ ";" ] | ";" ) ;
operator_symbol  = identifier | operator_token ;
type_parameters  = "<" identifier { "," identifier } ">" ;
parameters       = [ parameter { "," parameter } ] ;
parameter        = type identifier | type "..." identifier ;
type             = [ "const" ] qualified_name [ type_arguments ]
                   { "*" | "[" [ expression | type ] "]" | "[]" } ;
type_arguments   = "<" type { "," type } ">" ;
qualified_name   = identifier { "::" identifier } ;
top_level_statement = statement ;
block            = "{" { statement } "}" ;
variable_decl    = [ "const" | "static" ] type identifier
                   [ "=" expression ] ";" ;
for_init         = variable_decl | expression ;
statement        = block | variable_decl | expression [ ";" ]
                   | "return" [ expression ] [ ";" ]
                   | "yield" expression [ ";" ]
                   | "if" "(" expression ")" statement
                     [ "else" statement ]
                   | "while" "(" expression ")" statement
                   | "do" statement "while" "(" expression ")" [ ";" ]
                   | "for" "(" [ for_init ] ";" [ expression ] ";"
                     [ expression ] ")" statement
                   | "break" [ ";" ] | "continue" [ ";" ]
                   | "defer" statement ;
expression      = assignment_expression | if_expression
                   | switch_expression | block_expression ;
assignment_expression = logical_or_expression
                   [ assignment_operator assignment_expression ] ;
assignment_operator = "=" | "+=" | "-=" | "*=" | "/=" | "%="
                   | "<<=" | ">>=" | "&=" | "|=" | "^=" ;
if_expression   = "if" "(" expression ")" expression
                   [ "else" expression ] ;
switch_expression = "switch" "(" expression ")" "{"
                   { "case" expression [ ".." expression ]
                     "->" expression } "}" ;
block_expression = block ;
```

The primitive types are `void`, `bool`, `char`, `uchar`, `short`, `ushort`, `int`, `uint`, `long`, `ulong`, `float`, `double`, and library-provided `size_t`. Their representation follows the target C++ toolchain. `auto` is supported for local inference.

`T*` is a raw pointer. `T[N]` is a fixed-size array; `T[]` is a non-owning slice. In a type position, `Value[Key]` is a hashmap. The parser also accepts runtime-sized local arrays as `T[expression]`; because the parser distinguishes these from maps heuristically, ambiguous bracket forms should be written unambiguously.

Structs have named fields and may contain associated aliases. Struct literals support positional and named fields, for example `Point{1, 2}` and `Point{x: 1, y: 2}`. Missing fields are value-initialized by generated C++. A union overlays its fields and has no built-in active-member tag. Enums are named sets of enumerators and are referenced as `Enum::Member`.

Type aliases are transparent for type checking. Generic structs, unions, and functions use `<...>` type parameters. Concrete specializations are generated when required. An associated type can be selected with `Type::Alias`; generic associated aliases are substituted when the owning type is specialized.

A declaration may omit an explicit type-parameter list when its signature uses a bare single uppercase-letter type name, such as `T` or `U`, that is not otherwise declared. The checker then treats that name as an implicit type parameter. Explicit `T`-style parameters are still the preferred form for new code.

Expression bodies (`=> expression`) accept tuple parameters and tuple return types, as in `(T, U) to_tuple<T, U>(Pair<T, U> pair) => (pair.first, pair.second);`. Within a shorthand body, a parenthesized or bracketed postfix construct that starts on a new line is treated as the beginning of the next declaration, not as a call or index expression.

A numeric literal suffix can be handled by a function annotated `[userLiteral]`. The suffix names the conversion function; it must accept the literal value and return the desired user type. This is a conversion hook, not general compile-time evaluation.

Operator functions are declared with `[infix_operator]`, `[prefix_operator]`, or `[postfix_operator]`. The declared name follows the return type and is either an identifier, for example `Pair<A, B> to<A, B>(A left, B right)`, or a symbol enclosed in backticks, for example ``bool `<`(Measure left, Measure right)``, ``T `|>` <T>(T value, T (*fn)(T))``, and ``const char* `*` (const char* left, const char* right)``. Infix operators take exactly two parameters; prefix and postfix operators take exactly one. The checker diagnoses wrong arity and conflicting operator-kind attributes. Built-in symbols can be overloaded, and a matching operator declaration is tried before the built-in operation; this includes the relational spellings `<`, `<=`, `>`, and `>=`, the modulo spelling `%`, and the custom spellings `??`, `%%`, and `<=>`.

The function attribute `[no_custom_operators]` disables user-defined operator resolution within that function body. Built-in operator semantics are still checked and used, so pointer/null comparisons and ordinary arithmetic continue to work even if a matching custom operator is declared elsewhere. If an expression has no valid built-in interpretation but would match a custom operator, the checker reports that the custom operator is disabled. The restriction also applies when a generic function is instantiated.

Backticks distinguish a symbol operator name from the surrounding type syntax. In ``Vec2* `*`(Vec2 value, double scalar)`` the return type is `Vec2*` and the declared operator is `*`; in ``bool `<=`(Measure left, Measure right)`` the `<=` is an operator name rather than the start of a generic argument list or a comparison. A symbol-named operator declared without backticks is diagnosed. Backticks are declaration syntax only: uses are written with the bare operator, such as `a * b`, `a <= b`, or `a |> f`. Identifier-named operators such as `to` remain unquoted in declarations.

Importing a module makes its operator declarations available during parsing of the importing file. Both identifier-named operators such as `to` and `combine` and symbol-named operators such as `<`, `??`, `%%`, `|>`, and `<=>` are imported. Operators are imported wholesale even when the import has a selective symbol list, because an operator spelling cannot appear in that list; the selective import still restricts ordinary named symbols. Operator discovery follows imports transitively, so an operator re-exported through an intermediate module is also available.

## 4. Statements and scopes

The compiler supports local declarations, expression statements, blocks, `return`, `yield`, `if`/`else`, `switch`, `while`, `do ... while`, C-style `for`, `break`, `continue`, `defer`, and structural bindings. A local may have an explicit type or use `auto`; `auto` requires an initializer. The entry point is `main`; the backend emits a C++ `int main()` and translates a bare `return` from a source `void main()` to a successful process return.

Tuple structural binding uses `auto (first, second) = expression;`. Tuple members use numeric indices, such as `.0`. Structural binding also destructures fixed arrays, slices, and struct or union values positionally; bound names do not need to match struct field names, but their count and order must match the aggregate shape. For fixed arrays, the number of names must equal the compile-time array length. The backend emits C++ structured bindings for tuples and structs and element-wise copies for arrays and slices; slice access assumes the slice is long enough and does not insert a length check.

`defer statement;` registers the statement for scope exit. The backend implements this with an RAII guard, so deferred statements run when the corresponding C++ scope exits, including stack unwinding. Multiple guards are destroyed in reverse construction order. Cleanup timing therefore follows generated scopes, not textual line position.

## 5. Expressions

Expressions include literals, identifiers, qualified identifiers, calls, static-method calls, member access, indexing and slicing, struct literals, tuples, closures, casts, `sizeof`, unary and binary operators, assignments, `if`, `switch`, and block expressions.

The parser groups operators from lower to higher precedence as follows:

| Precedence, low to high | Operators |
|---|---|
| Assignment | `=`, `+=`, `-=`, `*=`, `/=`, `%=`, `<<=`, `>>=`, `&=`, `|=`, `^=` |
| User-defined infix (left-associative) | declared `[infix_operator]` symbols, including custom tokens such as `|>` |
| Logical OR | `||` |
| Logical AND | `&&` |
| Bitwise OR, XOR, AND | `|`, `^`, `&` |
| Equality | `==`, `!=` |
| Relational | `<`, `<=`, `>`, `>=` |
| Shift | `<<`, `>>` |
| Additive | `+`, `-` |
| Multiplicative | `*`, `/`, `%` |
| Cast and unary | `as`, unary `+`, `-`, `!`, `~`, `&`, `*`, `++`, `--`, `sizeof`, declared prefix operators |
| Postfix | calls, member access, indexing, slicing, postfix `++`, `--`, declared postfix operators |

Assignments are right-associative. Most arithmetic, pointer, and cast behavior follows the generated C++ expression. The type checker rejects a subset of invalid operations, but accepted casts and pointer operations are not runtime-checked.

User-defined infix operators are parsed at one defined precedence level, below all built-in binary operators, and are left-associative, so unknown symbols do not need a hard-coded precedence. Because a declared operator binds looser than comparison and arithmetic operators, mixed expressions require parentheses: `(3 combine 4) != 7`, `(1 %% 2) != 12`, and `(a ?? b) != 12`, not `3 combine 4 != 7`. Symbol spellings are encoded into generated function names (`|>` becomes `pipe_greaterthan`, `=` becomes `equal`, and so on). When an infix `|>` operator is declared and its right operand is a call, `value |> f(args)` is additionally lowered to `f(value, args)`; a non-call right operand resolves through the declared operator function.

### Contextual type inference

When a concrete expected type is available, the checker propagates it into an expression. Expected types come from declared variable initializers, function return types, assignment targets, tuple elements, struct fields, `if` and `switch` branches, and block yields. For a generic call, the expected result type is unified recursively with the function's declared return type; inferred bindings are combined with bindings from explicit type arguments and call arguments, and incompatible return candidates are rejected. This applies to direct, UFCS, user-literal, and static-method overload selection.

Expected-type propagation supplements rather than replaces argument inference. If neither arguments nor context determine a type parameter, the call is ambiguous and requires explicit type information. Conflicting explicit, argument-derived, and expected bindings are not silently treated as a successful specialization. Type aliases inside generic arguments are canonicalized when concrete generic aggregates are instantiated so generated C++ declarations and uses agree.

### `if` and `switch`

`if` may appear as a statement or expression. Expression branches produce values using `yield`; `else` is optional. If no branch is taken in an if-expression without an else, the generated expression uses a default-initialized result. This is not exhaustive control flow and may conceal a missing case.

`switch` is an expression with `case pattern -> expression` arms. Numeric inclusive ranges use `case low..high -> expression`. An arm may yield from a block. The backend does not synthesize a `default` arm when none is present; an unmatched value throws `std::logic_error` from the generated expression helper. Exhaustiveness and duplicate-case checking are limited.

### Calls, methods, and closures

Functions may be overloaded. Methods use `Owner::method`; static dispatch on a concrete generic type is supported. UFCS permits `value.method(args)` to call a compatible free or static function with the receiver as its first argument. Generic inference and variadic packing are supported in tested forms.

Closures use `{ typed_parameter -> expression; }` syntax and capture surrounding variables. Explicit closure parameter and return types inside generic function bodies are substituted for each concrete specialization. Function types in generic signatures are likewise specialized. The C++ backend generally represents function and closure values with `std::function`; this is not a guarantee of zero allocation or C function-pointer ABI compatibility.

## 6. Generic inference and specialization

Type parameters are inferred recursively from arguments and expected result types. Inferred structure can include pointers, arrays, slices, maps, tuples, function types, and generic aggregate arguments. A generic aggregate initializer can infer type arguments from its field values or from a concrete expected aggregate type. If inference remains incomplete (for example, an empty literal or a no-argument generic call without a concrete result context), supply explicit type arguments or a declaration with a concrete type.

Declarations may omit the explicit `<...>` list when their signatures mention an otherwise-undeclared bare single-letter type name. Such names are collected as implicit type parameters during registration so the declaration remains a template rather than becoming a reference to an undeclared struct.

Each function specialization is checked and emitted for its concrete binding set. Specializations for distinct types must remain independent; mutation of one specialization must not change another. Recursive generic aggregate instantiation is tracked while fields are resolved, allowing finite recursion through pointer-bearing wrappers. If resolving a generic declaration re-enters the same declaration with different type arguments, the checker diagnoses unbounded specialization expansion rather than recursing indefinitely. A recursively embedded by-value layout remains invalid in the C++ backend. The implementation is still experimental around mutually dependent parameters, overload ambiguity, and inference through more complex nested expressions; these are not promised to behave like a complete language-wide constraint solver.

## 7. Collections, pointers, and memory

Raw pointers can be dereferenced with `*` and addressed with `&`. Pointer field access automatically dereferences the receiver in supported member-access contexts. These features do not add null checks, bounds checks, borrowing, or lifetime tracking.

Fixed arrays and slices support indexing. The C++ backend emits fixed arrays as native C++ arrays (`T name[N]`), and fixed-array `.length` is emitted as the compile-time bound. C++ function parameters declared as fixed arrays follow C/C++ array-to-pointer parameter adjustment, which supports C-style interfaces. Glang initialization and copy assignment are lowered to element copies because C++ arrays cannot be assigned as whole values. Array fields participate recursively in generated equality and hashing. Slices remain non-owning `std::span` values with runtime length; retaining a slice beyond the lifetime of its backing storage is invalid. Runtime-sized local arrays are represented as vector-backed spans; returning or retaining such a span after its local backing vector has been destroyed is invalid.

`Value[Key]` maps to a C++ unordered map with Glang equality and hashing helpers. `map[key]` reads without inserting and yields `(value, found)`; assigning to `map[key]` inserts or replaces. Supported aggregate keys use recursive field equality and hashing. C-string pointers compare and hash by string contents. Union fields are compared and hashed by object representation, not by an active variant; padding and inactive bytes can affect results. Unsupported key types may fail while compiling generated C++.

`Box<T>` is a nullable reference-counted core type mapped to `std::shared_ptr<T>`. `Box<T>::new()` creates an initialized `T` with `std::make_shared<T>()`; `Box<T>::new(deleter)` creates one with a custom `void (*)(T*)` deleter, and `Box<T>::adopt(pointer, deleter)` takes ownership of an existing pointer with that deleter. `Box<T>::from(value)` and `to_box(value)` copy a value into a new box. Copying a `Box` shares ownership. It supports pointer-like dereference and field access. Converting a raw pointer to `Box<T>` with a cast creates a non-owning shared handle; the raw allocation must outlive all such handles. Use `adopt` when ownership should transfer.

Taking the address of a struct literal materializes storage. Within a block the temporary lasts until that block exits. In a pointer-returning expression body the backend heap-materializes the value so the returned pointer remains valid. Raw-pointer ownership remains the caller's responsibility.

`List<T>` is the managed dynamic array in the source standard library and maps to `std::vector<T>`; its elements are released with the vector and callers do not manually free its backing storage. Its API and iterator/invalidation guarantees are smaller than those of a mature standard container. `std.container.stack` and `std.container.queue` provide source-level `Stack<T>` and `Queue<T>` adapters over `List<T>`; their empty-capable operations return `(value, found)` tuples. `std.container.pair` provides `Pair<T, U>` with positional `first`/`second` fields. `std.container.set` provides a `Set<T>` backed by `List<T>` and a parallel active-flag list; `add`/`insert`, `contains`/`has`, `remove`/`erase`, `len`, `is_empty`, and `clear` are available, and removal deactivates a slot that re-insertion can reactivate. `Set<T>` does not require hashing; values must support `==`. `std.container.sequence` provides `List<T>`, the pull-based `Lazy<T>` sequence type, and integer ranges; `std.container.list` and `std.container.lazy` re-export it. `Lazy<T>` maps to a shared-state runtime sequence whose elements are produced only when a terminal operation pulls them. `to_lazy` wraps arrays, fixed arrays, slices, `List<T>` values, C strings (as `char` elements), existing lazy sequences, and `range` results; owned copies are made for non-lazy sources. `map`, `filter`, `take`, `drop`, `take_while`, `drop_while`, `stride`, `inspect`, `flat_map`, `enumerate`, `zip`, and `chain` are lazy combinators. `to_list`, `fold`, `reduce`, `count`, `count_if`, `any`, `all`, `sum`, `first`, `first_or`, `last_or`, `nth`, and `for_each` consume the sequence. Lazy sequences are single-pass and copies share progression state, so consuming one copy advances the others. `std::Option<T>` and `Result<T>` are source-level generic tagged-result conventions built from Glang aggregates/unions; the result helpers expose `Ok`/`Err` operations, and `isOk`/`isErr` are available as UFCS-compatible spellings of `is_ok`/`is_err`, but these types do not provide compiler-enforced exception or ownership propagation.

`std.memory.Owned<T>` represents a manually releasable allocation. Its `ptr` points to `T`, and its `count` is the number of allocated elements. `Result<Owned<T>>` is used by fallible ownership-producing helpers, including `fromValue`, `fromPtr`, `allocateOwned`, string duplication, `toOwned`, and `std.fs.read_to_string`. The caller must handle the error before accessing the value and release successful ownership with `std::memory::release(&owned)`. Release frees the allocation and clears the pointer/count. `fromPtr` adopts a non-null allocation; callers must transfer ownership and must not free it separately. The lower-level `std.memory.allocate` API returns a raw pointer and success flag for interoperation and requires manual matching cleanup.

## 8. Standard library and C interoperability

The source standard library includes modules for results, allocation, owned memory, strings, C file I/O, printing, managed lists, reference-counted boxes, encoding, hashing, containers, math, geometry, and other helpers. String helpers cover trimming, counting, replacement, comparison, parsing, a fixed-capacity `StringBuilder`, padding, and zero-allocation splitting/joining; `std.algo.search` and `std.algo.aggregate` provide array searching and reduction helpers; `std.fs.path` provides the `Path` value type and `std.fs.write` extends filesystem support; `std.io.error` writes to standard error; `std.math` provides C math bindings, numeric helpers, and a deterministic random generator; `std.encoding` provides hex and Base64 conversion; `std.hash` provides FNV-1a and djb2 hashing; `std.container` provides `BitSet` and `Heap<T>` alongside the sequence types; and `std.geom` provides vectors and rectangles. Aggregate modules `std.fs`, `std.string`, `std.container`, `std.math`, `std.geom`, and `std.encoding` import their component modules for convenience. It is not a complete platform-independent runtime. `std.fs.read_to_string(path)` returns `Result<Owned<char>>`; it allocates a NUL-terminated buffer and frees a partial buffer on a short read.

`Path` is a fixed-capacity value type with a `char[1024]` buffer, so it requires no destructor or ownership tracking. `std.fs.path` overloads `/` for every combination of `const char*` and `Path`, inserting a single separator, and `+` appends a suffix without a separator. `auto path = "C:" / "Users" / "mfana" / "Downloads";` produces `C:/Users/mfana/Downloads`. `parent`, `normalize`, `with_extension`, `is_absolute`, `file_name`, `extension`, and `has_extension` query or derive paths. `c_str()` and `to_string()` return a pointer into the Path buffer, so they must be called on an lvalue rather than a temporary.

`StringBuilder` is a fixed-capacity (`char[2048]`) value type. `builder()` creates an empty builder, `builder_from(text)` seeds one, and `append`/`<<` append strings, characters, integers, doubles, and booleans. Each append returns the updated builder, so chaining is assignment-based: `builder = builder << "value=" << 42;`. `to_string()`/`c_str()` expose the buffer; `clear`, `len`, `capacity`, and `is_empty` manage it. Appends beyond capacity are truncated.

`std.string.split` provides `split_count`, `split_view`/`split_next` for zero-allocation length-delimited iteration, in-place `split(char* text, char delimiter)` returning `List<char*>`, and `join` overloads that build a `StringBuilder` from a list or a `SplitView`. `std.string.pad` provides `pad_left`/`pad_start`, `pad_right`/`pad_end`, `pad_center`, `zfill`, `truncate_width`, and `repeat_text`, all returning `StringBuilder` values. `std.geom.vector` provides the value types `Vec2` and `Vec3`; `+`, `-`, unary `-`, scalar `*` and `/`, dot product through vector `*`, and 3D cross product through `%` are operator overloads, alongside `magnitude`, `normalized`, `distance`, and `lerp` helpers.

`std.encoding.hex` and `std.encoding.base64` encode into caller-provided buffers. Length helpers report the required capacity, including the terminating NUL; encoding and decoding return the number of units written, or `-1` for invalid input, a null pointer, or an insufficient buffer. `hex_valid` and `base64_valid` validate input without writing. `std.hash` provides FNV-1a 32-bit (`hash_string`, `hash_bytes`), djb2 64-bit (`hash_string64`, `hash_bytes64`), `hash_int`, and `hash_combine`; the byte variants hash exactly the requested length, including embedded NUL bytes.

`BitSet` is a growable bitset over 32-bit words. `make_bitset(count)` creates it, `bitset_resize` changes the addressable size, and `bitset_set`, `bitset_reset`, `bitset_toggle`, and `bitset_test` reject out-of-range indices rather than growing implicitly. `Heap<T>` is a binary min-heap over `List<T>` with `heap_push`, `heap_pop`, `heap_peek`, `heap_push_all`, and `heap_from`; empty-capable operations return `(value, found)`. `std.math.random` provides the xorshift64 `Rng` value type: `make_rng(seed)` and `rng_reseed` set state, pointer arguments advance it, and `rng_next`, `rng_next_uint`, `rng_next_int`, `rng_range`, `rng_double`, `rng_range_double`, `rng_bool`, `rng_roll`, and `rng_shuffle` provide random values and in-place shuffling. A zero seed is replaced by a fixed non-zero state.

`Rect` holds `double` fields `x`, `y`, `width`, and `height`. `make_rect` and `rect_from_points` construct rectangles; `rect_left`, `rect_right`, `rect_top`, `rect_bottom`, `rect_center_x`, `rect_center_y`, `rect_area`, and `rect_perimeter` query them; and `rect_contains`, `rect_contains_rect`, `rect_intersects`, `rect_intersection`, and `rect_union` handle spatial relations. `rect_inflate`, `rect_translate`, and `rect_scale` return adjusted copies, and the operator overloads `+`, `*`, and `<` denote union, scaling, and area comparison. A null-literal comparison such as `pointer == nullptr` always denotes built-in pointer comparison, even when a content-comparing `const char*` equality operator is in scope.

An external function may be declared with `[[extern]]`. Add `c_abi` for C linkage:

```glang
[[extern, c_abi]]
size_t fread(void* buffer, size_t itemSize, size_t itemCount, FILE* file);
```

Declarations must match the actual native ABI and headers. C variadic functions use an ellipsis parameter and retain C's default promotions and format-string hazards. Glang does not verify a format string against variadic arguments. Link libraries and search paths are supplied to the native build command using repeatable `-l` and `-L` options; these do not add include directories.

The C++ backend emits helper code for defer, maps, hashing/equality, core managed types, and collections. Generated symbol names, aggregate layout, and cross-translation-unit linkage are implementation details and are not a stable ABI.

## 9. Diagnostics, limitations, and conformance

The compiler reports lexical, parse, import, and type-checking diagnostics with source locations. Diagnostics and recovery are evolving; some errors can still surface only when the generated C++ is compiled. A program is practically usable only when both Glang translation and the chosen C++ compiler succeed.

The language currently does not promise:

- memory safety, ownership checking, null safety, or lifetime analysis for raw pointers and slices;
- automatic array bounds checking or checked casts;
- a fixed cross-platform ABI or fixed widths for target-dependent scalar types;
- tagged-union semantics, stable hash/equality for arbitrary object representations, or automatic hashing for every user type;
- complete overload resolution or universal generic inference in underconstrained expressions;
- a complete package manager, project build graph, native header discovery, or stable multi-translation-unit ABI;
- a production-grade LSP implementation or compatibility guarantees for standard-library APIs.

Use explicit types and casts at FFI boundaries, handle all `Result` values, pair raw allocations with their matching deallocator, and run generated programs under the target C++ toolchain. Changes to parser, type checker, code generator, or standard library should be accompanied by tests that transpile, compile, and execute representative programs.

## 10. Maturity assessment

**Rating: 5.5/10 as a language implementation; 7/10 as an experimental compiler prototype.** Glang has a broad and useful foundation—generics, associated aliases, contextual inference, collections, C interoperability, and a working C++ backend—but its memory and lifetime model, diagnostics, generic edge cases, portability guarantees, and build workflow are not yet mature. The highest-value improvements are stronger automated conformance testing across C++ toolchains, compiler-side diagnostics instead of generated-C++ failures, explicit lifetime/ownership rules, more complete contextual inference and overload resolution, and a stable project/dependency build system.
