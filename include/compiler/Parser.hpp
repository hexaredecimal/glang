#ifndef COMPILER_PARSER_HPP
#define COMPILER_PARSER_HPP

#include "Token.hpp"
#include "AST.hpp"
#include "CompilerError.hpp"
#include <vector>
#include <string>
#include <set>

namespace Glang {

class Parser {
public:
    Parser(std::vector<Token> tokens);

    std::shared_ptr<ProgramAST> parseProgram();
    const std::vector<Error>& errors() const { return m_errors; }
    bool hasErrors() const { return !m_errors.empty(); }

private:
    std::shared_ptr<ProgramAST> parseProgramImpl();
    void discoverImportedOperators();
    void discoverImportedOperators(std::set<std::string>& visited, int depth);
    const Token& peek() const;
    const Token& peekNext() const;
    const Token& previous() const;
    bool isAtEnd() const;
    Token advance();
    bool check(TokenKind kind) const;
    bool match(TokenKind kind);
    Token consume(TokenKind kind, const std::string& message);

    void error(const Location& loc, const std::string& message, const std::string& token = "");
    void synchronize();

    // Note:  Type AST parsing
    TypeASTPtr parseType();

    // Note:  Attributes
    std::vector<Attribute> parseAttributes();
    bool isAttributeNext();

    // Note:  Top level
    ImportStmtAST parseImport();
    DeclPtr parseDeclaration(const std::vector<Attribute>& preParsedAttributes = {});
    DeclPtr parseStructDecl();
    DeclPtr parseUnionDecl();
    DeclPtr parseEnumDecl();
    DeclPtr parseTypeAliasDecl();
    DeclPtr parseFunctionDecl(const std::vector<Attribute>& attributes = {});

    // Note:  Statements
    StmtPtr parseStatement();
    StmtPtr parseVarDeclStmt(bool isConst = false, bool isStatic = false);
    StmtPtr parseReturnStmt();
    StmtPtr parseYieldStmt();
    StmtPtr parseWhileStmt();
    StmtPtr parseDoWhileStmt();
    StmtPtr parseForStmt();
    StmtPtr parseDeferStmt();

    // Note:  Expressions
    ExprPtr parseExpression();
    ExprPtr parseAssignmentExpr();
    ExprPtr parseLogicalOr();
    ExprPtr parseLogicalAnd();
    ExprPtr parseBitwiseOr();
    ExprPtr parseBitwiseXor();
    ExprPtr parseBitwiseAnd();
    ExprPtr parseEquality();
    ExprPtr parseRelational();
    ExprPtr parseShift();
    ExprPtr parseAdditive();
    ExprPtr parseMultiplicative();
    ExprPtr parseCast();
    ExprPtr parseUnary();
    ExprPtr parsePostfix();
    ExprPtr parsePrimary();

    ExprPtr parseIfExpression();
    ExprPtr parseSwitchExpression();
    ExprPtr parseBlockExpression();
    ExprPtr parseClosureExpression();
    ExprPtr parseStructInitExpression(TypeASTPtr typeAst);

    bool isLambdaBlock();
    bool isDeclaredInfixOperator() const;
    bool isDeclaredPrefixOperator() const;
    bool isDeclaredPostfixOperator() const;

    std::vector<Token> m_tokens;
    size_t m_current{0};
    std::vector<Error> m_errors;
    bool m_inSwitchPattern{false};
    // While parsing a top-level `=>` function body, a postfix call/index that
    // starts on a new line begins the next declaration instead of continuing
    // the expression.
    bool m_stopPostfixAtNewline{false};
    // Allows `Vec2 *(Vec2, Vec2)` to parse the `*` as the operator name
    // instead of a pointer return type.
    bool m_parsingOperatorReturnType{false};
    std::set<std::string> m_declaredInfixOperators;
    std::set<std::string> m_declaredPrefixOperators;
    std::set<std::string> m_declaredPostfixOperators;
};

}  // namespace Glang

#endif
