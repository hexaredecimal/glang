#ifndef COMPILER_SYMBOLTABLE_HPP
#define COMPILER_SYMBOLTABLE_HPP

#include "Type.hpp"
#include "AST.hpp"
#include <string>
#include <unordered_map>
#include <vector>
#include <memory>

namespace Glang {

struct Symbol {
    std::string name;
    std::string mangledName;
    TypePtr type;
    bool isConst{false};
    bool isStatic{false};
    bool isType{false};
    bool isFunction{false};
    bool isTypeAlias{false};
    std::string ownerType;  // Note:  Non-empty if static method
    std::shared_ptr<FunctionDeclAST> funcAST{nullptr};
    std::shared_ptr<TypeAliasDeclAST> aliasAST{nullptr};
};

class Scope {
public:
    explicit Scope(std::shared_ptr<Scope> parent = nullptr) : m_parent(std::move(parent)) {}

    void define(const Symbol& sym) {
        m_symbols[sym.name] = sym;
    }

    Symbol* lookup(const std::string& name) {
        auto it = m_symbols.find(name);
        if (it != m_symbols.end()) return &it->second;
        if (m_parent) return m_parent->lookup(name);
        return nullptr;
    }

    const std::unordered_map<std::string, Symbol>& symbols() const { return m_symbols; }

    std::shared_ptr<Scope> parent() const { return m_parent; }

private:
    std::shared_ptr<Scope> m_parent;
    std::unordered_map<std::string, Symbol> m_symbols;
};

class SymbolTable {
public:
    SymbolTable();

    void enterScope();
    void enterClosureScope();
    void exitScope();

    void defineVar(const std::string& name, TypePtr type, bool isConst = false, bool isStatic = false);
    void defineType(const std::string& name, TypePtr type);
    void defineTypeAlias(const std::string& name, std::shared_ptr<TypeAliasDeclAST> aliasAST);
    void defineFunction(const std::string& name, const std::string& ownerType, TypePtr type, std::shared_ptr<FunctionDeclAST> funcAST = nullptr, const std::string& mangledName = "");

    Symbol* lookupVar(const std::string& name);
    Symbol* lookupType(const std::string& name);
    std::vector<Symbol*> lookupFunctions(const std::string& name);
    std::vector<Symbol*> lookupStaticMethods(const std::string& ownerType, const std::string& methodName);
    Symbol* lookupStaticMethod(const std::string& ownerType, const std::string& methodName);
    std::vector<Symbol*> lookupAllStaticMethods(const std::string& ownerType);

    std::shared_ptr<Scope> currentScope() const { return m_currentScope; }
    std::shared_ptr<Scope> globalScope() const { return m_globalScope; }
    const std::vector<std::shared_ptr<Symbol>>& allFunctions() const { return m_allFunctions; }

private:
    std::shared_ptr<Scope> m_globalScope;
    std::shared_ptr<Scope> m_currentScope;
    std::vector<std::shared_ptr<Scope>> m_scopeStack;
    std::vector<std::shared_ptr<Symbol>>
        m_allFunctions;  // Note:  All registered functions & methods
};

}  // namespace Glang

#endif
