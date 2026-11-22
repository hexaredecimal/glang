#include "compiler/SymbolTable.hpp"

namespace Glang {

SymbolTable::SymbolTable() {
  m_globalScope = std::make_shared<Scope>();
  m_currentScope = m_globalScope;

  // Define built-in primitive types
  std::vector<std::string> primitives = {
      "void", "bool", "char",  "uchar", "short",  "ushort", "int",
      "uint", "long", "ulong", "size_t", "float", "double", "auto"};
  for (const auto& p : primitives) {
    defineType(p, Type::makePrimitive(p));
  }
  defineVar("nullptr", Type::makePointer(Type::makePrimitive("void")), true);
}

void SymbolTable::enterScope() {
  m_scopeStack.push_back(m_currentScope);
  m_currentScope = std::make_shared<Scope>(m_currentScope);
}

void SymbolTable::enterClosureScope() {
  m_scopeStack.push_back(m_currentScope);
  m_currentScope = std::make_shared<Scope>(m_currentScope);
}

void SymbolTable::exitScope() {
  if (!m_scopeStack.empty()) {
    m_currentScope = m_scopeStack.back();
    m_scopeStack.pop_back();
  } else if (m_currentScope->parent()) {
    m_currentScope = m_currentScope->parent();
  }
}

void SymbolTable::defineVar(const std::string& name, TypePtr type, bool isConst, bool isStatic) {
  Symbol sym;
  sym.name = name;
  sym.type = type;
  sym.isConst = isConst;
  sym.isStatic = isStatic;
  m_currentScope->define(sym);
}

void SymbolTable::defineType(const std::string& name, TypePtr type) {
  Symbol sym;
  sym.name = name;
  sym.type = type;
  sym.isType = true;
  m_currentScope->define(sym);
}

void SymbolTable::defineTypeAlias(const std::string& name, std::shared_ptr<TypeAliasDeclAST> aliasAST) {
  Symbol sym;
  sym.name = name;
  sym.isType = true;
  sym.isTypeAlias = true;
  sym.aliasAST = std::move(aliasAST);
  m_currentScope->define(sym);
}

void SymbolTable::defineFunction(const std::string& name, const std::string& ownerType, TypePtr type, std::shared_ptr<FunctionDeclAST> funcAST, const std::string& mangledName) {
  auto symPtr = std::make_shared<Symbol>();
  symPtr->name = name;
  symPtr->ownerType = ownerType;
  symPtr->type = type;
  symPtr->isFunction = true;
  symPtr->funcAST = funcAST;
  symPtr->mangledName = mangledName;

  m_allFunctions.push_back(symPtr);

  if (ownerType.empty()) {
    m_globalScope->define(*symPtr);
  }
}

Symbol* SymbolTable::lookupVar(const std::string& name) {
  return m_currentScope->lookup(name);
}

Symbol* SymbolTable::lookupType(const std::string& name) {
  return m_currentScope->lookup(name);
}

std::vector<Symbol*> SymbolTable::lookupFunctions(const std::string& name) const {
  std::vector<Symbol*> matches;
  for (auto& sym : m_allFunctions) {
    if (sym && sym->name == name && sym->ownerType.empty()) {
      matches.push_back(sym.get());
    }
  }
  return matches;
}

std::vector<Symbol*> SymbolTable::lookupStaticMethods(const std::string& ownerType, const std::string& methodName) {
  std::vector<Symbol*> matches;
  for (auto& sym : m_allFunctions) {
    if (sym && sym->ownerType == ownerType && sym->name == methodName) {
      matches.push_back(sym.get());
    }
  }
  return matches;
}

Symbol* SymbolTable::lookupStaticMethod(const std::string& ownerType, const std::string& methodName) {
  auto matches = lookupStaticMethods(ownerType, methodName);
  if (!matches.empty()) return matches[0];
  return nullptr;
}

std::vector<Symbol*> SymbolTable::lookupAllStaticMethods(const std::string& ownerType) {
  std::vector<Symbol*> matches;
  for (auto& sym : m_allFunctions) {
    if (sym && sym->ownerType == ownerType) {
      matches.push_back(sym.get());
    }
  }
  return matches;
}

}  // namespace Glang
