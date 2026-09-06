#include "compiler/Token.hpp"

namespace Glang {

std::string tokenKindToString(TokenKind kind) {
    switch (kind) {
        case TokenKind::EndOfFile: return "EndOfFile";
        case TokenKind::Invalid: return "Invalid";

        case TokenKind::KwImport: return "import";
        case TokenKind::KwStruct: return "struct";
        case TokenKind::KwUnion: return "union";
        case TokenKind::KwEnum: return "enum";
        case TokenKind::KwConst: return "const";
        case TokenKind::KwStatic: return "static";
        case TokenKind::KwAuto: return "auto";
        case TokenKind::KwIf: return "if";
        case TokenKind::KwElse: return "else";
        case TokenKind::KwSwitch: return "switch";
        case TokenKind::KwCase: return "case";
        case TokenKind::KwYield: return "yield";
        case TokenKind::KwReturn: return "return";
        case TokenKind::KwWhile: return "while";
        case TokenKind::KwDo: return "do";
        case TokenKind::KwFor: return "for";
        case TokenKind::KwVoid: return "void";
        case TokenKind::KwBool: return "bool";
        case TokenKind::KwChar: return "char";
        case TokenKind::KwUChar: return "uchar";
        case TokenKind::KwShort: return "short";
        case TokenKind::KwUShort: return "ushort";
        case TokenKind::KwInt: return "int";
        case TokenKind::KwUInt: return "uint";
        case TokenKind::KwLong: return "long";
        case TokenKind::KwULong: return "ulong";
        case TokenKind::KwFloat: return "float";
        case TokenKind::KwDouble: return "double";
        case TokenKind::KwTrue: return "true";
        case TokenKind::KwFalse: return "false";
        case TokenKind::KwAs: return "as";
        case TokenKind::KwDefer: return "defer";
        case TokenKind::KwType: return "type";
        case TokenKind::KwNullptr: return "nullptr";
        case TokenKind::KwSizeof: return "sizeof";
        case TokenKind::KwDefault: return "default";
        case TokenKind::KwBreak: return "break";
        case TokenKind::KwContinue: return "continue";

        case TokenKind::Identifier: return "Identifier";
        case TokenKind::IntegerLiteral: return "IntegerLiteral";
        case TokenKind::FloatLiteral: return "FloatLiteral";
        case TokenKind::CharLiteral: return "CharLiteral";
        case TokenKind::StringLiteral: return "StringLiteral";

        case TokenKind::Plus: return "+";
        case TokenKind::Minus: return "-";
        case TokenKind::Star: return "*";
        case TokenKind::Slash: return "/";
        case TokenKind::Percent: return "%";
        case TokenKind::PlusPlus: return "++";
        case TokenKind::MinusMinus: return "--";
        case TokenKind::Assign: return "=";
        case TokenKind::PlusAssign: return "+=";
        case TokenKind::MinusAssign: return "-=";
        case TokenKind::StarAssign: return "*=";
        case TokenKind::SlashAssign: return "/=";
        case TokenKind::PercentAssign: return "%=";
        case TokenKind::LessLessAssign: return "<<=";
        case TokenKind::GreaterGreaterAssign: return ">>=";
        case TokenKind::AmpersandAssign: return "&=";
        case TokenKind::PipeAssign: return "|=";
        case TokenKind::CaretAssign: return "^=";
        case TokenKind::Equal: return "==";
        case TokenKind::NotEqual: return "!=";
        case TokenKind::Less: return "<";
        case TokenKind::LessEqual: return "<=";
        case TokenKind::Greater: return ">";
        case TokenKind::GreaterEqual: return ">=";
        case TokenKind::LessLess: return "<<";
        case TokenKind::GreaterGreater: return ">>";
        case TokenKind::Ampersand: return "&";
        case TokenKind::AndAnd: return "&&";
        case TokenKind::Pipe: return "|";
        case TokenKind::PipePipe: return "||";
        case TokenKind::Caret: return "^";
        case TokenKind::Tilde: return "~";
        case TokenKind::Exclamation: return "!";
        case TokenKind::Question: return "?";
        case TokenKind::Arrow: return "->";
        case TokenKind::FatArrow: return "=>";
        case TokenKind::DoubleColon: return "::";
        case TokenKind::Dot: return ".";
        case TokenKind::DotDot: return "..";
        case TokenKind::DotDotDot: return "...";
        case TokenKind::Comma: return ",";
        case TokenKind::Semicolon: return ";";
        case TokenKind::Colon: return ":";
        case TokenKind::LParen: return "(";
        case TokenKind::RParen: return ")";
        case TokenKind::LBrace: return "{";
        case TokenKind::RBrace: return "}";
        case TokenKind::LBracket: return "[";
        case TokenKind::RBracket: return "]";
    }
    return "Unknown";
}

std::string Token::toString() const {
    return "[" + loc.toString() + "] " + tokenKindToString(kind) + " ('" + lexeme + "')";
}

}  // namespace Glang
