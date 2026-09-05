#ifndef COMPILER_LEXER_HPP
#define COMPILER_LEXER_HPP

#include "Token.hpp"
#include "CompilerError.hpp"
#include <vector>
#include <string>
#include <unordered_map>

namespace Glang {

class Lexer {
public:
    Lexer(std::string filename, std::string source);

    std::vector<Token> tokenize();
    const std::vector<Error>& errors() const { return m_errors; }
    bool hasErrors() const { return !m_errors.empty(); }

private:
    char peek() const;
    char peekNext() const;
    char advance();
    bool isAtEnd() const;
    bool match(char expected);

    std::string skipWhitespaceAndComments();
    Token lexIdentifierOrKeyword();
    Token lexNumber();
    Token lexString();
    Token lexChar();

    std::string m_filename;
    std::string m_source;
    size_t m_cursor{0};
    int m_line{1};
    int m_column{1};

    std::unordered_map<std::string, TokenKind> m_keywords;
    std::vector<Error> m_errors;
};

}  // namespace Glang

#endif
