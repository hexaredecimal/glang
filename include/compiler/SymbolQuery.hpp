#ifndef COMPILER_SYMBOLQUERY_HPP
#define COMPILER_SYMBOLQUERY_HPP

#include "AST.hpp"
#include "Type.hpp"
#include "Token.hpp"
#include "Location.hpp"
#include "SymbolTable.hpp"
#include <string>
#include <vector>
#include <memory>

namespace Glang {

struct SymbolMember {
    std::string name;
    std::string type;
    std::string kind;  // Note:  "field", "static_method", "method",
                       // "enum_member", "property", "type"
    std::string signature;
    std::string doc;
};

struct SymbolQueryResult {
    bool found{false};
    std::string name;
    std::string type;
    std::string
        kind;  // Note:  "variable", "parameter", "function", "static_method",
               // "struct", "union", "enum", "enum_member", "field", "property",
               // "type_alias", "constant", "type", "scope"
    std::string signature;
    std::string file;
    int line{0};
    int column{0};
    int declLine{0};
    int declColumn{0};
    std::string doc;
    std::vector<SymbolMember> members;
    std::string error;

    std::string toJSON() const;
};

class SymbolQueryEngine {
public:
    SymbolQueryEngine(std::shared_ptr<ProgramAST> program,
                      const std::vector<Token>& tokens,
                      const SymbolTable& symTable);

    // Note:  General query with automatic smart context deduction from
    // line/column/symbolName
    SymbolQueryResult query(const std::string& file, int line, int column, const std::string& symbolName = "");

    // Note:  Query specific nested scoped symbol: e.g. "Foo::Bar",
    // "Math::Utils::PI"
    SymbolQueryResult queryScopedSymbol(const std::string& fullScopedPath);

    // Note:  Enumerate static methods, enum members, and types attached to a
    // scope e.g. "Foo::"
    SymbolQueryResult enumerateScope(const std::string& scopeName, const std::string& filterPrefix = "");

    // Note:  Enumerate fields, properties, and methods on a type or expression
    // e.g. "point." or "user.address."
    SymbolQueryResult enumerateTypeMembers(TypePtr type, const std::string& filterPrefix = "");
    SymbolQueryResult enumerateExpressionMembers(const std::string& exprStr, const std::string& filterPrefix = "", int line = 0, int column = 0);

    // Note:  Deduce type of an expression string in context
    TypePtr deduceExpressionType(const std::string& exprStr, int line = 0, int column = 0);

    struct Candidate {
        std::string name;
        TypePtr type{nullptr};
        std::string kind;
        Location loc;
        Location declLoc;
        std::string doc;
        std::string signature;
        Location scopeStart;
        Location scopeEnd;
        int score{0};
    };

    const std::vector<Candidate>& candidates() const { return m_candidates; }

private:
    void collectSymbols();
    void visitDecl(DeclPtr decl);
    void visitStmt(StmtPtr stmt);
    void visitExpr(ExprPtr expr);
    void addCandidate(const std::string& name, TypePtr type, const std::string& kind, const Location& loc, const Location& declLoc = Location(), const std::string& doc = "", const std::string& signature = "", const Location& scopeStart = Location(), const Location& scopeEnd = Location());

    std::shared_ptr<ProgramAST> m_program;
    std::vector<Token> m_tokens;
    SymbolTable m_symbolTable;
    std::vector<Candidate> m_candidates;
};

}  // namespace Glang

#endif
