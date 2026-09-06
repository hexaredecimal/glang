#ifndef COMPILER_TOKEN_HPP
#define COMPILER_TOKEN_HPP

#include "Location.hpp"
#include <string>

namespace Glang {

enum class TokenKind {
    // Special
    EndOfFile,
    Invalid,

    // Keywords
    KwImport,
    KwStruct,
    KwUnion,
    KwEnum,
    KwConst,
    KwStatic,
    KwAuto,
    KwIf,
    KwElse,
    KwSwitch,
    KwCase,
    KwYield,
    KwReturn,
    KwWhile,
    KwDo,
    KwFor,
    KwVoid,
    KwBool,
    KwChar,
    KwUChar,
    KwShort,
    KwUShort,
    KwInt,
    KwUInt,
    KwLong,
    KwULong,
    KwFloat,
    KwDouble,
    KwTrue,
    KwFalse,
    KwAs,
    KwDefer,
    KwType,
    KwNullptr,
    KwSizeof,
    KwDefault,
    KwBreak,
    KwContinue,

    // Identifiers & Literals
    Identifier,
    IntegerLiteral,
    FloatLiteral,
    CharLiteral,
    StringLiteral,

    // Operators & Symbols
    Plus,          // +
    Minus,         // -
    Star,          // *
    Slash,         // /
    Percent,       // %
    PlusPlus,      // ++
    MinusMinus,    // --
    Assign,        // =
    PlusAssign,    // +=
    MinusAssign,   // -=
    StarAssign,    // *=
    SlashAssign,   // /=
    PercentAssign, // %=
    LessLessAssign,       // <<=
    GreaterGreaterAssign, // >>=
    AmpersandAssign,      // &=
    PipeAssign,           // |=
    CaretAssign,          // ^=
    Equal,         // ==
    NotEqual,      // !=
    Less,          // <
    LessEqual,     // <=
    Greater,       // >
    GreaterEqual,  // >=
    LessLess,      // <<
    GreaterGreater,// >>
    Ampersand,     // &
    AndAnd,        // &&
    Pipe,          // |
    PipePipe,      // ||
    Caret,         // ^
    Tilde,         // ~
    Exclamation,   // !
    Question,      // ?
    Arrow,         // ->
    FatArrow,      // =>
    DoubleColon,   // ::
    Dot,           // .
    DotDot,        // ..
    DotDotDot,     // ...
    Comma,         // ,
    Semicolon,     // ;
    Colon,         // :
    LParen,        // (
    RParen,        // )
    LBrace,        // {
    RBrace,        // }
    LBracket,      // [
    RBracket       // ]
};

std::string tokenKindToString(TokenKind kind);

struct Token {
    TokenKind kind{TokenKind::Invalid};
    std::string lexeme;
    Location loc;
    std::string suffix;
    std::string leadingDoc;

    Token() = default;
    Token(TokenKind k, std::string lex, Location l, std::string doc = "")
        : kind(k), lexeme(std::move(lex)), loc(std::move(l)), leadingDoc(std::move(doc)) {}

    std::string toString() const;
};

}  // namespace Glang

#endif
