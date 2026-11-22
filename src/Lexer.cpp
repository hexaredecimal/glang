#include "compiler/Lexer.hpp"
#include <cctype>

namespace Glang {

Lexer::Lexer(std::string filename, std::string source)
    : m_filename(std::move(filename)), m_source(std::move(source)) {
  m_keywords = {
      {"import", TokenKind::KwImport}, {"struct", TokenKind::KwStruct},
      {"union", TokenKind::KwUnion},   {"enum", TokenKind::KwEnum},
      {"const", TokenKind::KwConst},   {"static", TokenKind::KwStatic},
      {"auto", TokenKind::KwAuto},     {"if", TokenKind::KwIf},
      {"else", TokenKind::KwElse},     {"switch", TokenKind::KwSwitch},
      {"case", TokenKind::KwCase},     {"yield", TokenKind::KwYield},
      {"return", TokenKind::KwReturn}, {"while", TokenKind::KwWhile},
      {"do", TokenKind::KwDo},         {"for", TokenKind::KwFor},
      {"void", TokenKind::KwVoid},     {"bool", TokenKind::KwBool},
      {"char", TokenKind::KwChar},     {"uchar", TokenKind::KwUChar},
      {"short", TokenKind::KwShort},   {"ushort", TokenKind::KwUShort},
      {"int", TokenKind::KwInt},       {"uint", TokenKind::KwUInt},
      {"long", TokenKind::KwLong},     {"ulong", TokenKind::KwULong},
      {"float", TokenKind::KwFloat},   {"double", TokenKind::KwDouble},
      {"true", TokenKind::KwTrue},     {"false", TokenKind::KwFalse},
      {"as", TokenKind::KwAs},         {"defer", TokenKind::KwDefer},
      {"type", TokenKind::KwType},     {"nullptr", TokenKind::KwNullptr},
      {"sizeof", TokenKind::KwSizeof}, {"default", TokenKind::KwDefault},
      {"break", TokenKind::KwBreak},   {"continue", TokenKind::KwContinue}};
}

char Lexer::peek() const {
  if (isAtEnd()) return '\0';
  return m_source[m_cursor];
}

char Lexer::peekNext() const {
  if (m_cursor + 1 >= m_source.size()) return '\0';
  return m_source[m_cursor + 1];
}

char Lexer::advance() {
  if (isAtEnd()) return '\0';
  char c = m_source[m_cursor++];
  if (c == '\n') {
    m_line++;
    m_column = 1;
  } else {
    m_column++;
  }
  return c;
}

bool Lexer::isAtEnd() const { return m_cursor >= m_source.size(); }

bool Lexer::match(char expected) {
  if (isAtEnd() || m_source[m_cursor] != expected) return false;
  advance();
  return true;
}

std::string Lexer::lexEscapeSequence() {
  if (isAtEnd()) return {};

  char escape = advance();
  switch (escape) {
    case 'a':
      return std::string(1, '\a');
    case 'b':
      return std::string(1, '\b');
    case 'f':
      return std::string(1, '\f');
    case 'n':
      return std::string(1, '\n');
    case 'r':
      return std::string(1, '\r');
    case 't':
      return std::string(1, '\t');
    case 'v':
      return std::string(1, '\v');
    case '\\':
    case '\'':
    case '"':
    case '?':
      return std::string(1, escape);
    case '\n':
      return {};
    case '\r':
      if (peek() == '\n') advance();
      return {};
    default:
      break;
  }

  if (escape >= '0' && escape <= '7') {
    unsigned int value = static_cast<unsigned int>(escape - '0');
    for (int i = 0; i < 2 && peek() >= '0' && peek() <= '7'; ++i) {
      value = (value << 3) | static_cast<unsigned int>(advance() - '0');
    }
    return std::string(1, static_cast<char>(value & 0xff));
  }

  if (escape == 'x') {
    unsigned int value = 0;
    bool hasDigits = false;
    while (!isAtEnd() && std::isxdigit(static_cast<unsigned char>(peek()))) {
      char digit = advance();
      unsigned int nibble = digit >= '0' && digit <= '9'
                                ? static_cast<unsigned int>(digit - '0')
                                : static_cast<unsigned int>(
                                      std::tolower(static_cast<unsigned char>(digit)) -
                                      'a' + 10);
      value = ((value << 4) | nibble) & 0xff;
      hasDigits = true;
    }
    if (hasDigits) return std::string(1, static_cast<char>(value));
  }

  return std::string({'\\', escape});
}

std::string Lexer::skipWhitespaceAndComments() {
  std::string comments;
  while (!isAtEnd()) {
    char c = peek();
    if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
      advance();
    } else if (c == '/' && peekNext() == '/') {
      advance();
      advance();

      while (!isAtEnd() && peek() == '/') {
        advance();
      }

      if (!isAtEnd() && (peek() == ' ' || peek() == '\t')) advance();
      std::string lineComment;
      while (!isAtEnd() && peek() != '\n') {
        lineComment += advance();
      }

      while (!lineComment.empty() &&
             (lineComment.back() == ' ' || lineComment.back() == '\r' ||
              lineComment.back() == '\t')) {
        lineComment.pop_back();
      }

      if (!lineComment.empty()) {
        if (!comments.empty()) comments += "\n";
        comments += lineComment;
      }
    } else if (c == '/' && peekNext() == '*') {
      advance();
      advance();

      if (!isAtEnd() && peek() == '*') {
        advance();
      }

      std::string blockComment;

      while (!isAtEnd()) {
        if (peek() == '*' && peekNext() == '/') {
          advance();
          advance();
          break;
        }
        blockComment += advance();
      }

      size_t bStart = 0;

      while (bStart < blockComment.size() &&
             (blockComment[bStart] == ' ' || blockComment[bStart] == '\t' ||
              blockComment[bStart] == '\n' || blockComment[bStart] == '\r' ||
              blockComment[bStart] == '*')) {
        bStart++;
      }

      size_t bEnd = blockComment.size();

      while (bEnd > bStart &&
             (blockComment[bEnd - 1] == ' ' || blockComment[bEnd - 1] == '\t' ||
              blockComment[bEnd - 1] == '\n' ||
              blockComment[bEnd - 1] == '\r' ||
              blockComment[bEnd - 1] == '*')) {
        bEnd--;
      }
      std::string trimmedBlock = blockComment.substr(bStart, bEnd - bStart);
      if (!trimmedBlock.empty()) {
        if (!comments.empty()) comments += "\n";
        comments += trimmedBlock;
      }
    } else {
      break;
    }
  }
  return comments;
}

Token Lexer::lexIdentifierOrKeyword() {
  Location startLoc(m_filename, m_line, m_column);
  std::string lexeme;
  while (!isAtEnd() && (std::isalnum(peek()) || peek() == '_')) {
    lexeme += advance();
  }

  auto it = m_keywords.find(lexeme);
  if (it != m_keywords.end()) {
    return Token(it->second, lexeme, startLoc);
  }
  return Token(TokenKind::Identifier, lexeme, startLoc);
}

Token Lexer::lexNumber() {
  Location startLoc(m_filename, m_line, m_column);
  std::string lexeme;
  bool isFloat = false;

  while (!isAtEnd() && (std::isdigit(peek()) || peek() == '_')) {
    char c = advance();
    if (c != '_') lexeme += c;
  }

  if (!isAtEnd() && peek() == '.' && std::isdigit(peekNext())) {
    isFloat = true;
    lexeme += advance();  // Note:  '.'
    while (!isAtEnd() && (std::isdigit(peek()) || peek() == '_')) {
      char c = advance();
      if (c != '_') lexeme += c;
    }
  }

  std::string suffix;
  if (!isAtEnd() && (std::isalpha(peek()) || peek() == '_')) {
    while (!isAtEnd() && (std::isalnum(peek()) || peek() == '_')) {
      suffix += advance();
    }
  }

  Token tok(isFloat ? TokenKind::FloatLiteral : TokenKind::IntegerLiteral,
            lexeme, startLoc);
  tok.suffix = suffix;
  return tok;
}

Token Lexer::lexString() {
  Location startLoc(m_filename, m_line, m_column);
  advance();  // Note:  consume opening "
  std::string value;

  while (!isAtEnd() && peek() != '"') {
    if (peek() == '\\') {
      advance();
      value += lexEscapeSequence();
    } else {
      value += advance();
    }
  }

  if (!isAtEnd()) advance();  // Note:  consume closing "

  std::string suffix;
  if (!isAtEnd() && (std::isalpha(peek()) || peek() == '_')) {
    while (!isAtEnd() && (std::isalnum(peek()) || peek() == '_')) {
      suffix += advance();
    }
  }


  Token tok(TokenKind::StringLiteral, value, startLoc);
  tok.suffix = suffix;
  return tok;
}

Token Lexer::lexChar() {
  Location startLoc(m_filename, m_line, m_column);
  advance();  // Note:  consume opening '
  std::string value;
  if (!isAtEnd() && peek() != '\'') {
    if (peek() == '\\') {
      advance();
      value += lexEscapeSequence();
    } else {
      value += advance();
    }
  }
  if (!isAtEnd()) advance();  // Note:  consume closing '

  std::string suffix;
  if (!isAtEnd() && (std::isalpha(peek()) || peek() == '_')) {
    while (!isAtEnd() && (std::isalnum(peek()) || peek() == '_')) {
      suffix += advance();
    }
  }

  Token tok(TokenKind::CharLiteral, value, startLoc);
  tok.suffix = suffix;
  return tok;
}

Token Lexer::lexQuotedOperator() {
  Location startLoc(m_filename, m_line, m_column);
  advance();  // Note: consume opening '`'

  std::string value;
  while (!isAtEnd() && peek() != '`' && peek() != '\n') {
    value += advance();
  }

  if (isAtEnd() || peek() != '`') {
    m_errors.emplace_back("Unterminated quoted operator name", startLoc.line,
                          startLoc.column, m_filename, value);
    return Token(TokenKind::Invalid, value, startLoc);
  }
  advance();  // Note: consume closing '`'

  size_t begin = value.find_first_not_of(" \t");
  size_t end = value.find_last_not_of(" \t");
  std::string name =
      begin == std::string::npos ? "" : value.substr(begin, end - begin + 1);

  if (name.empty()) {
    m_errors.emplace_back("Quoted operator name must not be empty",
                          startLoc.line, startLoc.column, m_filename, value);
    return Token(TokenKind::Invalid, name, startLoc);
  }

  static const std::string symbolChars = "+-*/%^~!?<>=&|:.@$#\\";
  for (char ch : name) {
    if (std::isalnum(static_cast<unsigned char>(ch)) || ch == '_') continue;
    if (symbolChars.find(ch) != std::string::npos) continue;
    m_errors.emplace_back("Invalid character '" + std::string(1, ch) +
                              "' in quoted operator name",
                          startLoc.line, startLoc.column, m_filename, value);
    return Token(TokenKind::Invalid, name, startLoc);
  }

  return Token(TokenKind::QuotedOperator, std::move(name), startLoc);
}

Token Lexer::lexOperator() {
  Location loc(m_filename, m_line, m_column);
  char c = peek();
  Token tok{};
  advance();  // Note:  consume char

  auto isOperatorSymbol = [](char ch) {
    switch (ch) {
      case '+': case '-': case '*': case '/': case '%': case '^':
      case '~': case '!': case '?': case '<': case '>': case '=':
      case '&': case '|': case ':': case '.': case '@': case '$':
      case '#': case '\\':
        return true;
      default:
        return false;
    }
  };
  auto custom = [&](std::string lexeme) {
    while (isOperatorSymbol(peek())) {
      lexeme += advance();
    }
    return Token(TokenKind::CustomOperator, std::move(lexeme), loc);
  };

  // Symbols that cannot start any built-in operator are user-defined
  // operators. Consume the whole symbol run and preserve its spelling.
  if (c == '@' || c == '$' || c == '#' || c == '\\') {
    return custom(std::string(1, c));
  }
  // Unknown combinations such as `|>`, `??`, or `<=>` must stay a single
  // token so the parser can treat them as one infix/postfix operator.  The
  // first character of a custom operator may also be a built-in operator
  // character; only sequences that are not themselves built-in tokens are
  // captured here.
  //
  // Repeated symbols are only merged when the doubled spelling has no
  // built-in meaning. `**`, `!!`, and `~~` must stay split so pointer-to-
  // pointer types and repeated unary operators keep working; `*...` must
  // stay split for variadic parameters.
  auto isCustomTail = [](char first, char next) {
    switch (next) {
      case '|': case '~': case '?': case '@': case '$': case '#':
      case '\\':
        return true;
      case '<': case '>':
        return first == '|' || first == '~' || first == '?' ||
               first == '=';
      case '%': case '^':
        return next == first;
      default:
        return false;
    }
  };
  const std::string currentPair =
      std::string(1, c) + std::string(1, peek());
  const bool isBuiltinPair = currentPair == "->" || currentPair == "=>" ||
                             currentPair == "||";
  const bool startsKnownCustomTail =
      !isBuiltinPair && isCustomTail(c, peek()) &&
      std::string("+-*/%^~!?<>=&|:.").find(c) != std::string::npos;
  const bool startsSpaceship = c == '<' && peek() == '=' && peekNext() == '>';
  if (startsKnownCustomTail || startsSpaceship || (c == '<' && peek() == '>')) {
    return custom(std::string(1, c));
  }

  switch (c) {
    case '+':
      if (match('+'))
        tok = Token(TokenKind::PlusPlus, "++", loc);
      else if (match('='))
        tok = Token(TokenKind::PlusAssign, "+=", loc);
      else
        tok = Token(TokenKind::Plus, "+", loc);
      break;
    case '-':
      if (match('-'))
        tok = Token(TokenKind::MinusMinus, "--", loc);
      else if (match('='))
        tok = Token(TokenKind::MinusAssign, "-=", loc);
      else if (match('>'))
        tok = Token(TokenKind::Arrow, "->", loc);
      else
        tok = Token(TokenKind::Minus, "-", loc);
      break;
    case '*':
      if (match('='))
        tok = Token(TokenKind::StarAssign, "*=", loc);
      else
        tok = Token(TokenKind::Star, "*", loc);
      break;
    case '/':
      if (match('='))
        tok = Token(TokenKind::SlashAssign, "/=", loc);
      else
        tok = Token(TokenKind::Slash, "/", loc);
      break;
    case '%':
      if (match('='))
        tok = Token(TokenKind::PercentAssign, "%=", loc);
      else
        tok = Token(TokenKind::Percent, "%", loc);
      break;
    case '^':
      if (match('='))
        tok = Token(TokenKind::CaretAssign, "^=", loc);
      else
        tok = Token(TokenKind::Caret, "^", loc);
      break;
    case '~':
      tok = Token(TokenKind::Tilde, "~", loc);
      break;
    case '?':
      tok = Token(TokenKind::Question, "?", loc);
      break;
    case '=':
      if (match('='))
        tok = Token(TokenKind::Equal, "==", loc);
      else if (match('>'))
        tok = Token(TokenKind::FatArrow, "=>", loc);
      else
        tok = Token(TokenKind::Assign, "=", loc);
      break;
    case '!':
      if (match('='))
        tok = Token(TokenKind::NotEqual, "!=", loc);
      else
        tok = Token(TokenKind::Exclamation, "!", loc);
      break;
    case '<':
      if (match('<')) {
        if (match('='))
          tok = Token(TokenKind::LessLessAssign, "<<=", loc);
        else
          tok = Token(TokenKind::LessLess, "<<", loc);
      } else if (match('=')) {
        tok = Token(TokenKind::LessEqual, "<=", loc);
      } else {
        tok = Token(TokenKind::Less, "<", loc);
      }
      break;
    case '>':
      if (match('=')) {
        tok = Token(TokenKind::GreaterEqual, ">=", loc);
      } else {
        tok = Token(TokenKind::Greater, ">", loc);
      }
      break;
    case '&':
      if (match('&'))
        tok = Token(TokenKind::AndAnd, "&&", loc);
      else if (match('='))
        tok = Token(TokenKind::AmpersandAssign, "&=", loc);
      else
        tok = Token(TokenKind::Ampersand, "&", loc);
      break;
    case '|':
      if (match('|'))
        tok = Token(TokenKind::PipePipe, "||", loc);
      else if (match('='))
        tok = Token(TokenKind::PipeAssign, "|=", loc);
      else
        tok = Token(TokenKind::Pipe, "|", loc);
      break;
    case ':':
      if (match(':'))
        tok = Token(TokenKind::DoubleColon, "::", loc);
      else
        tok = Token(TokenKind::Colon, ":", loc);
      break;
    case '.':
      if (match('.')) {
        if (match('.'))
          tok = Token(TokenKind::DotDotDot, "...", loc);
        else
          tok = Token(TokenKind::DotDot, "..", loc);
      } else {
        tok = Token(TokenKind::Dot, ".", loc);
      }
      break;
    case ',':
      tok = Token(TokenKind::Comma, ",", loc);
      break;
    case ';':
      tok = Token(TokenKind::Semicolon, ";", loc);
      break;
    case '(':
      tok = Token(TokenKind::LParen, "(", loc);
      break;
    case ')':
      tok = Token(TokenKind::RParen, ")", loc);
      break;
    case '{':
      tok = Token(TokenKind::LBrace, "{", loc);
      break;
    case '}':
      tok = Token(TokenKind::RBrace, "}", loc);
      break;
    case '[':
      tok = Token(TokenKind::LBracket, "[", loc);
      break;
    case ']':
      tok = Token(TokenKind::RBracket, "]", loc);
      break;
    default:
      tok = Token(TokenKind::Invalid, std::string(1, c), loc);
      m_errors.emplace_back("Unexpected character '" + std::string(1, c) + "'",
                            loc.line, loc.column, loc.filename,
                            std::string(1, c));
      break;
  }

  return tok;
}

std::vector<Token> Lexer::tokenize() {
  std::vector<Token> tokens;

  while (!isAtEnd()) {
    std::string doc = skipWhitespaceAndComments();
    if (isAtEnd()) break;

    char c = peek();

    Token tok;
    if (std::isalpha(c) || c == '_')
      tok = lexIdentifierOrKeyword();
    else if (std::isdigit(c))
      tok = lexNumber();
    else if (c == '"')
      tok = lexString();
    else if (c == '\'')
      tok = lexChar();
    else if (c == '`')
      tok = lexQuotedOperator();
    else
      tok = lexOperator();

    if (!doc.empty()) {
      tok.leadingDoc = doc;
    }
    tokens.push_back(std::move(tok));
  }
  tokens.emplace_back(TokenKind::EndOfFile, "",
                      Location(m_filename, m_line, m_column));
  return tokens;
}

}  // namespace Glang
