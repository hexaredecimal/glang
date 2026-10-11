#include "compiler/SymbolQuery.hpp"
#include <sstream>
#include <algorithm>
#include <cmath>
#include <cctype>

namespace Glang {

static std::string escapeJSON(const std::string& s) {
  std::ostringstream o;
  for (char c : s) {
    if (c == '"')
      o << "\\\"";
    else if (c == '\\')
      o << "\\\\";
    else if (c == '\b')
      o << "\\b";
    else if (c == '\f')
      o << "\\f";
    else if (c == '\n')
      o << "\\n";
    else if (c == '\r')
      o << "\\r";
    else if (c == '\t')
      o << "\\t";
    else
      o << c;
  }
  return o.str();
}

static std::string toLower(const std::string& s) {
  std::string res = s;
  for (char& c : res)
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  return res;
}

static int levenshteinDistance(const std::string& s1, const std::string& s2) {
  size_t len1 = s1.size();
  size_t len2 = s2.size();
  if (len1 == 0) return static_cast<int>(len2);
  if (len2 == 0) return static_cast<int>(len1);

  std::vector<std::vector<int>> d(len1 + 1, std::vector<int>(len2 + 1));
  for (size_t i = 0; i <= len1; ++i) d[i][0] = static_cast<int>(i);
  for (size_t j = 0; j <= len2; ++j) d[0][j] = static_cast<int>(j);

  for (size_t i = 1; i <= len1; ++i) {
    for (size_t j = 1; j <= len2; ++j) {
      int cost = (std::tolower(static_cast<unsigned char>(s1[i - 1])) ==
                  std::tolower(static_cast<unsigned char>(s2[j - 1])))
                     ? 0
                     : 1;
      d[i][j] = (std::min)({
          d[i - 1][j] + 1,        // deletion
          d[i][j - 1] + 1,        // insertion
          d[i - 1][j - 1] + cost  // substitution
      });
    }
  }
  return d[len1][len2];
}

std::string SymbolQueryResult::toJSON() const {
  std::ostringstream json;
  json << "{\n";
  json << "  \"found\": " << (found ? "true" : "false") << ",\n";
  json << "  \"name\": \"" << escapeJSON(name) << "\",\n";
  json << "  \"type\": \"" << escapeJSON(type) << "\",\n";
  json << "  \"kind\": \"" << escapeJSON(kind) << "\",\n";
  json << "  \"file\": \"" << escapeJSON(file) << "\",\n";
  json << "  \"line\": " << line << ",\n";
  json << "  \"column\": " << column;
  if (!signature.empty()) {
    json << ",\n  \"signature\": \"" << escapeJSON(signature) << "\"";
  }
  if (declLine > 0) {
    json << ",\n  \"declLine\": " << declLine << ",\n";
    json << "  \"declColumn\": " << declColumn;
  }
  if (!doc.empty()) {
    json << ",\n  \"doc\": \"" << escapeJSON(doc) << "\"";
  }
  if (!members.empty()) {
    json << ",\n  \"members\": [\n";
    for (size_t i = 0; i < members.size(); ++i) {
      const auto& m = members[i];
      json << "    {\n";
      json << "      \"name\": \"" << escapeJSON(m.name) << "\",\n";
      json << "      \"type\": \"" << escapeJSON(m.type) << "\",\n";
      json << "      \"kind\": \"" << escapeJSON(m.kind) << "\",\n";
      json << "      \"signature\": \"" << escapeJSON(m.signature) << "\"";
      if (!m.doc.empty()) {
        json << ",\n      \"doc\": \"" << escapeJSON(m.doc) << "\"";
      }
      json << "\n    }" << (i + 1 < members.size() ? "," : "") << "\n";
    }
    json << "  ]";
  }
  if (!error.empty()) {
    json << ",\n  \"error\": \"" << escapeJSON(error) << "\"";
  }
  json << "\n}\n";
  return json.str();
}

SymbolQueryEngine::SymbolQueryEngine(std::shared_ptr<ProgramAST> program,
                                     const std::vector<Token>& tokens,
                                     const SymbolTable& symTable)
    : m_program(std::move(program)), m_tokens(tokens), m_symbolTable(symTable) {
  collectSymbols();
}

void SymbolQueryEngine::addCandidate(const std::string& name, TypePtr type, const std::string& kind, const Location& loc, const Location& declLoc, const std::string& doc, const std::string& signature, const Location& scopeStart, const Location& scopeEnd) {
  if (name.empty()) return;
  Candidate c;
  c.name = name;
  c.type = type;
  c.kind = kind;
  c.loc = loc;
  c.declLoc = declLoc;
  c.doc = doc;
  c.signature = signature;
  c.scopeStart = scopeStart;
  c.scopeEnd = scopeEnd;
  m_candidates.push_back(c);
}

void SymbolQueryEngine::collectSymbols() {
  if (!m_program) return;

  for (const auto& decl : m_program->declarations) {
    visitDecl(decl);
  }
  for (const auto& stmt : m_program->topStatements) {
    visitStmt(stmt);
  }
}

void SymbolQueryEngine::visitDecl(DeclPtr decl) {
  if (!decl) return;

  if (auto fDecl = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
    TypePtr fnType = fDecl->inferredType;
    if (!fnType) {
      std::vector<TypePtr> pTypes;
      for (const auto& p : fDecl->parameters) {
        pTypes.push_back(p.typeAst ? Type::makePrimitive(p.typeAst->name)
                                   : Type::makeUnknown());
      }
      TypePtr ret = fDecl->returnTypeAst
                        ? Type::makePrimitive(fDecl->returnTypeAst->name)
                        : Type::makePrimitive("void");
      fnType = Type::makeFunction(pTypes, ret);
    }

    std::string kind =
        fDecl->ownerTypeName.empty() ? "function" : "static_method";
    std::string fullName = fDecl->ownerTypeName.empty()
                               ? fDecl->name
                               : fDecl->ownerTypeName + "::" + fDecl->name;
    std::string funcDoc = !fDecl->doc.empty()
                              ? fDecl->doc
                              : "Function / static method: " + fullName;

    // Construct full signature: e.g. "int add(int a, int b)"
    std::string retStr =
        fDecl->returnTypeAst
            ? fDecl->returnTypeAst->name
            : (fnType && fnType->returnType ? fnType->returnType->toString()
                                            : "void");
    std::string sig = retStr + " " + fullName + "(";
    for (size_t i = 0; i < fDecl->parameters.size(); ++i) {
      if (i > 0) sig += ", ";
      const auto& p = fDecl->parameters[i];
      std::string pTypeStr = p.typeAst ? p.typeAst->name : "auto";
      sig += pTypeStr + " " + p.name;
    }
    sig += ")";

    Location funcEnd = fDecl->endLoc.line > 0 ? fDecl->endLoc : fDecl->loc;

    addCandidate(fullName, fnType, kind, fDecl->loc, fDecl->loc, funcDoc, sig,
                 fDecl->loc, funcEnd);
    if (!fDecl->ownerTypeName.empty()) {
      addCandidate(fDecl->name, fnType, kind, fDecl->loc, fDecl->loc, funcDoc,
                   sig, fDecl->loc, funcEnd);
    }

    // Parameters - scoped strictly within this function's location range!
    for (const auto& p : fDecl->parameters) {
      TypePtr pType = p.typeAst ? Type::makePrimitive(p.typeAst->name)
                                : Type::makeUnknown();
      Location pLoc = p.typeAst ? p.typeAst->loc : fDecl->loc;
      std::string pDoc =
          !p.doc.empty() ? p.doc : "Parameter '" + p.name + "' of " + fullName;
      std::string pSig = (p.typeAst ? p.typeAst->name : "auto") + " " + p.name;
      addCandidate(p.name, pType, "parameter", pLoc, fDecl->loc, pDoc, pSig,
                   fDecl->loc, funcEnd);
    }

    // Body
    if (fDecl->body) {
      visitExpr(fDecl->body);
    }
  } else if (auto sDecl = std::dynamic_pointer_cast<StructDeclAST>(decl)) {
    TypePtr sType = Type::makeStruct(sDecl->name);
    for (const auto& f : sDecl->fields) {
      TypePtr fType = f.typeAst ? Type::makePrimitive(f.typeAst->name)
                                : Type::makeUnknown();
      sType->fields.push_back({f.name, fType});
    }
    std::string structDoc =
        !sDecl->doc.empty() ? sDecl->doc : "Struct type: " + sDecl->name;
    addCandidate(sDecl->name, sType, "struct", sDecl->loc, sDecl->loc,
                 structDoc);
    for (const auto& f : sDecl->fields) {
      TypePtr fType = f.typeAst ? Type::makePrimitive(f.typeAst->name)
                                : Type::makeUnknown();
      Location fLoc = f.typeAst ? f.typeAst->loc : sDecl->loc;
      std::string fieldDoc =
          !f.doc.empty() ? f.doc
                         : "Field '" + f.name + "' of struct " + sDecl->name;
      addCandidate(f.name, fType, "field", fLoc, sDecl->loc, fieldDoc);
      addCandidate(sDecl->name + "." + f.name, fType, "field", fLoc, sDecl->loc,
                   fieldDoc);
    }
  } else if (auto uDecl = std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
    TypePtr uType = Type::makeUnion(uDecl->name);
    for (const auto& f : uDecl->fields) {
      TypePtr fType = f.typeAst ? Type::makePrimitive(f.typeAst->name)
                                : Type::makeUnknown();
      uType->fields.push_back({f.name, fType});
    }
    std::string unionDoc =
        !uDecl->doc.empty() ? uDecl->doc : "Union type: " + uDecl->name;
    addCandidate(uDecl->name, uType, "union", uDecl->loc, uDecl->loc, unionDoc);
    for (const auto& f : uDecl->fields) {
      TypePtr fType = f.typeAst ? Type::makePrimitive(f.typeAst->name)
                                : Type::makeUnknown();
      Location fLoc = f.typeAst ? f.typeAst->loc : uDecl->loc;
      std::string fieldDoc =
          !f.doc.empty() ? f.doc
                         : "Field '" + f.name + "' of union " + uDecl->name;
      addCandidate(f.name, fType, "field", fLoc, uDecl->loc, fieldDoc);
      addCandidate(uDecl->name + "." + f.name, fType, "field", fLoc, uDecl->loc,
                   fieldDoc);
    }
  } else if (auto eDecl = std::dynamic_pointer_cast<EnumDeclAST>(decl)) {
    TypePtr eType = Type::makeEnum(eDecl->name, eDecl->enumerators);
    std::string enumDoc =
        !eDecl->doc.empty() ? eDecl->doc : "Enum type: " + eDecl->name;
    addCandidate(eDecl->name, eType, "enum", eDecl->loc, eDecl->loc, enumDoc);
    for (size_t i = 0; i < eDecl->members.size(); ++i) {
      const auto& m = eDecl->members[i];
      std::string memDoc =
          !m.doc.empty() ? m.doc
                         : "Enumerator '" + m.name + "' of enum " + eDecl->name;
      addCandidate(m.name, eType, "enum_member", eDecl->loc, eDecl->loc,
                   memDoc);
      addCandidate(eDecl->name + "::" + m.name, eType, "enum_member",
                   eDecl->loc, eDecl->loc, memDoc);
    }
  } else if (auto aDecl = std::dynamic_pointer_cast<TypeAliasDeclAST>(decl)) {
    TypePtr aType = aDecl->targetTypeAst
                        ? Type::makePrimitive(aDecl->targetTypeAst->name)
                        : Type::makeUnknown();
    std::string aliasDoc =
        !aDecl->doc.empty() ? aDecl->doc : "Type alias: " + aDecl->aliasName;
    addCandidate(aDecl->aliasName, aType, "type_alias", aDecl->loc, aDecl->loc,
                 aliasDoc);
  }
}

void SymbolQueryEngine::visitStmt(StmtPtr stmt) {
  if (!stmt) return;

  if (auto vStmt = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
    TypePtr vType = vStmt->inferredType;
    if (!vType && vStmt->typeAst) {
      vType = Type::makePrimitive(vStmt->typeAst->name);
    }
    std::string varDoc = !vStmt->doc.empty() ? vStmt->doc : "";
    addCandidate(vStmt->name, vType, vStmt->isConst ? "constant" : "variable",
                 vStmt->loc, vStmt->loc, varDoc);
    if (vStmt->initializer) {
      visitExpr(vStmt->initializer);
    }
  } else if (auto eStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
    visitExpr(eStmt->expr);
  } else if (auto rStmt = std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
    if (rStmt->value) visitExpr(rStmt->value);
  } else if (auto yStmt = std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
    if (yStmt->value) visitExpr(yStmt->value);
  } else if (auto dStmt = std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
    visitStmt(dStmt->deferredStmt);
  } else if (auto wStmt = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
    visitExpr(wStmt->condition);
    visitStmt(wStmt->body);
  } else if (auto dwStmt = std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
    visitStmt(dwStmt->body);
    visitExpr(dwStmt->condition);
  } else if (auto fStmt = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
    if (fStmt->init) visitStmt(fStmt->init);
    if (fStmt->condition) visitExpr(fStmt->condition);
    if (fStmt->post) visitExpr(fStmt->post);
    if (fStmt->body) visitStmt(fStmt->body);
  } else if (auto taStmt = std::dynamic_pointer_cast<TypeAliasStmtAST>(stmt)) {
    if (taStmt->decl) visitDecl(taStmt->decl);
  }
}

void SymbolQueryEngine::visitExpr(ExprPtr expr) {
  if (!expr) return;

  if (auto idExpr = std::dynamic_pointer_cast<IdentifierExprAST>(expr)) {
    addCandidate(idExpr->name, idExpr->inferredType, "variable", idExpr->loc);
  } else if (auto scExpr =
                 std::dynamic_pointer_cast<ScopedIdentifierExprAST>(expr)) {
    addCandidate(scExpr->scopeName + "::" + scExpr->memberName,
                 scExpr->inferredType, "scoped_identifier", scExpr->loc);
    addCandidate(scExpr->memberName, scExpr->inferredType, "enum_member",
                 scExpr->loc);
  } else if (auto memExpr =
                 std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) {
    // Check if memberName is a function in the symbol table (for UFCS or member
    // functions)
    auto fnSyms = m_symbolTable.lookupFunctions(memExpr->memberName);
    if (!fnSyms.empty() && fnSyms[0]->type) {
      auto fnSym = fnSyms[0];
      Location declLoc = fnSym->funcAST ? fnSym->funcAST->loc : memExpr->loc;
      std::string doc = fnSym->funcAST && !fnSym->funcAST->doc.empty()
                            ? fnSym->funcAST->doc
                            : ("Function: " + memExpr->memberName);
      std::string sig;
      if (fnSym->funcAST) {
        std::string retStr = fnSym->funcAST->returnTypeAst
                                 ? fnSym->funcAST->returnTypeAst->name
                                 : "void";
        sig = retStr + " " + memExpr->memberName + "(";
        for (size_t i = 0; i < fnSym->funcAST->parameters.size(); ++i) {
          if (i > 0) sig += ", ";
          const auto& p = fnSym->funcAST->parameters[i];
          sig += (p.typeAst ? p.typeAst->name : "auto") + " " + p.name;
        }
        sig += ")";
      } else {
        std::string retStr = fnSym->type->returnType
                                 ? fnSym->type->returnType->toString()
                                 : "void";
        sig = retStr + " " + memExpr->memberName + "(";
        for (size_t i = 0; i < fnSym->type->paramTypes.size(); ++i) {
          if (i > 0) sig += ", ";
          sig += fnSym->type->paramTypes[i]
                     ? fnSym->type->paramTypes[i]->toString()
                     : "auto";
        }
        sig += ")";
      }
      addCandidate(memExpr->memberName, fnSym->type, "function", memExpr->loc,
                   declLoc, doc, sig);
    } else {
      addCandidate(memExpr->memberName, memExpr->inferredType, "field",
                   memExpr->loc);
    }
    visitExpr(memExpr->object);
  } else if (auto smCall =
                 std::dynamic_pointer_cast<StaticMethodCallExprAST>(expr)) {
    addCandidate(smCall->targetType + "::" + smCall->methodName,
                 smCall->inferredType, "static_method", smCall->loc);
    addCandidate(smCall->methodName, smCall->inferredType, "static_method",
                 smCall->loc);
    for (const auto& arg : smCall->arguments) {
      visitExpr(arg);
    }
  } else if (auto callExpr = std::dynamic_pointer_cast<CallExprAST>(expr)) {
    visitExpr(callExpr->callee);
    for (const auto& arg : callExpr->arguments) {
      visitExpr(arg);
    }
  } else if (auto binExpr = std::dynamic_pointer_cast<BinaryExprAST>(expr)) {
    visitExpr(binExpr->left);
    visitExpr(binExpr->right);
  } else if (auto unExpr = std::dynamic_pointer_cast<UnaryExprAST>(expr)) {
    if (unExpr->operand) visitExpr(unExpr->operand);
  } else if (auto blkExpr = std::dynamic_pointer_cast<BlockExprAST>(expr)) {
    for (const auto& s : blkExpr->statements) {
      visitStmt(s);
    }
    if (blkExpr->yieldExpr) visitExpr(blkExpr->yieldExpr);
  } else if (auto ifExpr = std::dynamic_pointer_cast<IfExprAST>(expr)) {
    visitExpr(ifExpr->condition);
    visitExpr(ifExpr->thenBranch);
    if (ifExpr->elseBranch) visitExpr(ifExpr->elseBranch);
  } else if (auto swExpr = std::dynamic_pointer_cast<SwitchExprAST>(expr)) {
    visitExpr(swExpr->targetExpr);
    for (const auto& c : swExpr->cases) {
      if (c.pattern) visitExpr(c.pattern);
      if (c.body) visitExpr(c.body);
    }
  } else if (auto clsExpr = std::dynamic_pointer_cast<ClosureExprAST>(expr)) {
    for (const auto& p : clsExpr->params) {
      TypePtr pType = p.typeAst ? Type::makePrimitive(p.typeAst->name)
                                : Type::makeUnknown();
      addCandidate(p.name, pType, "parameter", clsExpr->loc);
    }
    if (clsExpr->body) visitExpr(clsExpr->body);
  } else if (auto assExpr = std::dynamic_pointer_cast<AssignExprAST>(expr)) {
    visitExpr(assExpr->target);
    visitExpr(assExpr->value);
  } else if (auto castExpr = std::dynamic_pointer_cast<CastExprAST>(expr)) {
    visitExpr(castExpr->expr);
  } else if (auto arrLit =
                 std::dynamic_pointer_cast<ArrayLiteralExprAST>(expr)) {
    for (const auto& e : arrLit->elements) visitExpr(e);
  } else if (auto tupLit =
                 std::dynamic_pointer_cast<TupleLiteralExprAST>(expr)) {
    for (const auto& e : tupLit->elements) visitExpr(e);
  } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(expr)) {
    for (const auto& ent : mapLit->entries) {
      visitExpr(ent.first);
      visitExpr(ent.second);
    }
  } else if (auto idxExpr = std::dynamic_pointer_cast<IndexExprAST>(expr)) {
    visitExpr(idxExpr->target);
    visitExpr(idxExpr->index);
  } else if (auto slcExpr = std::dynamic_pointer_cast<SliceExprAST>(expr)) {
    visitExpr(slcExpr->target);
    if (slcExpr->startExpr) visitExpr(slcExpr->startExpr);
    if (slcExpr->endExpr) visitExpr(slcExpr->endExpr);
  } else if (auto stInit = std::dynamic_pointer_cast<StructInitExprAST>(expr)) {
    if (stInit->structType) {
      addCandidate(stInit->structType->name,
                   Type::makeStruct(stInit->structType->name), "struct",
                   stInit->structType->loc);
    }
    for (const auto& fi : stInit->fieldInits) {
      addCandidate(fi.first, fi.second ? fi.second->inferredType : nullptr,
                   "field", fi.second ? fi.second->loc : stInit->loc);
      if (fi.second) visitExpr(fi.second);
    }
  } else if (auto yldExpr = std::dynamic_pointer_cast<YieldExprAST>(expr)) {
    if (yldExpr->yieldedExpr) visitExpr(yldExpr->yieldedExpr);
  }
}

SymbolQueryResult SymbolQueryEngine::queryScopedSymbol(const std::string& fullScopedPath) {
  SymbolQueryResult res;
  res.name = fullScopedPath;

  size_t lastSep = fullScopedPath.rfind("::");
  if (lastSep == std::string::npos) {
    return query("", 0, 0, fullScopedPath);
  }

  std::string scopeName = fullScopedPath.substr(0, lastSep);
  std::string memberName = fullScopedPath.substr(lastSep + 2);

  // Check if scopeName is Enum and memberName is an enumerator (exact or
  // near match)
  Symbol* enumSym = m_symbolTable.lookupType(scopeName);
  if (enumSym && enumSym->type && enumSym->type->isEnum()) {
    std::string bestEnumMember;
    int bestEnumScore = -1000;

    for (const auto& en : enumSym->type->enumerators) {
      int score = 0;
      if (en == memberName)
        score = 2000;
      else if (toLower(en) == toLower(memberName))
        score = 1800;
      else if (!memberName.empty() && en.rfind(memberName, 0) == 0)
        score = 1500 - (static_cast<int>(en.length()) -
                        static_cast<int>(memberName.length())) *
                           5;
      else if (!memberName.empty() &&
               toLower(en).rfind(toLower(memberName), 0) == 0)
        score = 1300 - (static_cast<int>(en.length()) -
                        static_cast<int>(memberName.length())) *
                           5;
      else if (!memberName.empty()) {
        int dist = levenshteinDistance(en, memberName);
        if (dist <= 2) score = 1000 - dist * 100;
      }

      if (score > bestEnumScore) {
        bestEnumScore = score;
        bestEnumMember = en;
      }
    }

    if (bestEnumScore > 0) {
      res.found = true;
      res.name = scopeName + "::" + bestEnumMember;
      res.type = enumSym->type->toString();
      res.kind = "enum_member";

      for (const auto& cand : m_candidates) {
        if (cand.name == scopeName + "::" + bestEnumMember &&
            !cand.doc.empty()) {
          res.doc = cand.doc;
          break;
        }
      }
      if (res.doc.empty()) {
        res.doc =
            "Enumerator '" + bestEnumMember + "' of enum '" + scopeName + "'";
      }
      return res;
    }
  }

  // Check if static method on owner type
  auto smSyms = m_symbolTable.lookupAllStaticMethods(scopeName);
  Symbol* bestMethod = nullptr;
  int bestMethodScore = -1000;

  for (Symbol* sm : smSyms) {
    if (!sm) continue;
    int score = 0;
    if (sm->name == memberName)
      score = 2000;
    else if (toLower(sm->name) == toLower(memberName))
      score = 1800;
    else if (!memberName.empty() && sm->name.rfind(memberName, 0) == 0)
      score = 1500 - (static_cast<int>(sm->name.length()) -
                      static_cast<int>(memberName.length())) *
                         5;
    else if (!memberName.empty() &&
             toLower(sm->name).rfind(toLower(memberName), 0) == 0)
      score = 1300 - (static_cast<int>(sm->name.length()) -
                      static_cast<int>(memberName.length())) *
                         5;
    else if (!memberName.empty()) {
      int dist = levenshteinDistance(sm->name, memberName);
      if (dist <= 2) score = 1000 - dist * 100;
    }

    if (score > bestMethodScore) {
      bestMethodScore = score;
      bestMethod = sm;
    }
  }

  if (bestMethod && bestMethodScore > 0) {
    res.found = true;
    res.name = scopeName + "::" + bestMethod->name;
    res.type = bestMethod->type ? bestMethod->type->toString() : "fn()";
    res.kind = "static_method";

    for (const auto& cand : m_candidates) {
      if (cand.name == scopeName + "::" + bestMethod->name &&
          !cand.doc.empty()) {
        res.doc = cand.doc;
        break;
      }
    }
    if (res.doc.empty()) {
      res.doc = "Static method '" + bestMethod->name + "' of type '" +
                scopeName + "'";
    }
    if (bestMethod->funcAST) {
      res.declLine = bestMethod->funcAST->loc.line;
      res.declColumn = bestMethod->funcAST->loc.column;
      res.file = bestMethod->funcAST->loc.filename;
    }
    return res;
  }

  // Candidate near lookup
  const Candidate* bestCand = nullptr;
  int bestScore = -10000;

  for (const auto& cand : m_candidates) {
    int score = 0;
    if (cand.name == fullScopedPath)
      score = 2500;
    else if (toLower(cand.name) == toLower(fullScopedPath))
      score = 2000;
    else if (cand.name.rfind(scopeName + "::", 0) == 0) {
      std::string sub = cand.name.substr(scopeName.length() + 2);
      if (sub == memberName)
        score = 2000;
      else if (!memberName.empty() && sub.rfind(memberName, 0) == 0)
        score = 1600 - (static_cast<int>(sub.length()) -
                        static_cast<int>(memberName.length())) *
                           5;
      else if (!memberName.empty() &&
               toLower(sub).rfind(toLower(memberName), 0) == 0)
        score = 1400 - (static_cast<int>(sub.length()) -
                        static_cast<int>(memberName.length())) *
                           5;
      else if (!memberName.empty()) {
        int dist = levenshteinDistance(sub, memberName);
        if (dist <= 2) score = 1100 - dist * 100;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestCand = &cand;
    }
  }

  if (bestCand && bestScore > 0) {
    res.found = true;
    res.name = bestCand->name;
    res.type = bestCand->type ? bestCand->type->toString() : "unknown";
    res.kind = bestCand->kind;
    res.declLine = bestCand->declLoc.line;
    res.declColumn = bestCand->declLoc.column;
    res.file = bestCand->loc.filename;
    res.doc = bestCand->doc;
    return res;
  }

  res.found = false;
  res.type = "unknown";
  res.kind = "unknown";
  res.error = "Scoped symbol '" + fullScopedPath + "' not found in scope '" +
              scopeName + "'";
  return res;
}

SymbolQueryResult SymbolQueryEngine::enumerateScope(const std::string& scopeName, const std::string& filterPrefix) {
  SymbolQueryResult res;
  res.name = scopeName;
  res.kind = "scope";

  bool matchesFound = false;

  // Check Enum members
  Symbol* typeSym = m_symbolTable.lookupType(scopeName);
  if (typeSym && typeSym->type) {
    res.type = typeSym->type->toString();

    if (typeSym->type->isEnum()) {
      res.kind = "enum";
      for (const auto& cand : m_candidates) {
        if (cand.name == scopeName && cand.kind == "enum" &&
            !cand.doc.empty()) {
          res.doc = cand.doc;
          break;
        }
      }
      if (res.doc.empty()) res.doc = "Enum '" + scopeName + "' members";

      for (const auto& en : typeSym->type->enumerators) {
        bool matchPfx = filterPrefix.empty() ||
                        en.rfind(filterPrefix, 0) == 0 ||
                        toLower(en).rfind(toLower(filterPrefix), 0) == 0;
        if (!matchPfx && !filterPrefix.empty()) {
          matchPfx = (levenshteinDistance(en, filterPrefix) <= 2);
        }

        if (matchPfx) {
          std::string memDoc;
          for (const auto& cand : m_candidates) {
            if ((cand.name == scopeName + "::" + en || cand.name == en) &&
                cand.kind == "enum_member" && !cand.doc.empty()) {
              memDoc = cand.doc;
              break;
            }
          }
          if (memDoc.empty())
            memDoc = "Enumerator '" + en + "' of enum " + scopeName;

          SymbolMember m;
          m.name = en;
          m.type = scopeName;
          m.kind = "enum_member";
          m.signature = scopeName + "::" + en;
          m.doc = memDoc;
          res.members.push_back(m);
          matchesFound = true;
        }
      }
    }
  }

  // Check Static Methods on this type
  auto staticMethods = m_symbolTable.lookupAllStaticMethods(scopeName);
  for (Symbol* sm : staticMethods) {
    if (!sm) continue;
    bool matchPfx = filterPrefix.empty() ||
                    sm->name.rfind(filterPrefix, 0) == 0 ||
                    toLower(sm->name).rfind(toLower(filterPrefix), 0) == 0;
    if (!matchPfx && !filterPrefix.empty()) {
      matchPfx = (levenshteinDistance(sm->name, filterPrefix) <= 2);
    }

    if (matchPfx) {
      std::string smDoc;
      for (const auto& cand : m_candidates) {
        if (cand.name == scopeName + "::" + sm->name && !cand.doc.empty()) {
          smDoc = cand.doc;
          break;
        }
      }
      if (smDoc.empty()) smDoc = "Static method on " + scopeName;

      SymbolMember m;
      m.name = sm->name;
      m.type = sm->type ? sm->type->toString() : "fn()";
      m.kind = "static_method";
      m.signature = scopeName + "::" + sm->name +
                    (sm->type ? "(" + sm->type->toString() + ")" : "()");
      m.doc = smDoc;
      res.members.push_back(m);
      matchesFound = true;
    }
  }

  // Check Candidates starting with scopeName::
  std::string prefix = scopeName + "::";
  for (const auto& cand : m_candidates) {
    if (cand.name.rfind(prefix, 0) == 0) {
      std::string subName = cand.name.substr(prefix.length());
      bool matchPfx = filterPrefix.empty() ||
                      subName.rfind(filterPrefix, 0) == 0 ||
                      toLower(subName).rfind(toLower(filterPrefix), 0) == 0;
      if (!matchPfx && !filterPrefix.empty()) {
        matchPfx = (levenshteinDistance(subName, filterPrefix) <= 2);
      }

      if (matchPfx) {
        bool alreadyExists = false;
        for (const auto& em : res.members) {
          if (em.name == subName) {
            alreadyExists = true;
            break;
          }
        }
        if (!alreadyExists) {
          SymbolMember m;
          m.name = subName;
          m.type = cand.type ? cand.type->toString() : "unknown";
          m.kind = cand.kind;
          m.signature = prefix + subName;
          m.doc = cand.doc;
          res.members.push_back(m);
          matchesFound = true;
        }
      }
    }
  }

  if (matchesFound || typeSym) {
    res.found = true;
    if (res.type.empty()) res.type = scopeName;
    return res;
  }

  res.found = false;
  res.type = "unknown";
  res.error =
      "Scope or type '" + scopeName + "' not found or has no static members";
  return res;
}

SymbolQueryResult SymbolQueryEngine::enumerateTypeMembers(TypePtr type, const std::string& filterPrefix) {
  SymbolQueryResult res;
  if (!type) {
    res.found = false;
    res.error = "Cannot enumerate members of null type";
    return res;
  }

  // Dereference pointer if needed
  TypePtr rawType = type->isPointer() ? type->pointerBase : type;
  res.type = rawType ? rawType->toString() : "unknown";
  res.name = rawType ? rawType->name : "";

  if (!rawType) {
    res.found = false;
    res.error = "Unknown type";
    return res;
  }

  // Struct or Union fields
  if (rawType->isStruct() || rawType->isUnion()) {
    res.kind = rawType->isStruct() ? "struct" : "union";
    res.found = true;

    // If fields empty on rawType, look up in symbol table
    const auto& fields = rawType->fields;
    if (fields.empty() && !rawType->name.empty()) {
      Symbol* sSym = m_symbolTable.lookupType(rawType->name);
      if (sSym && sSym->type && !sSym->type->fields.empty()) {
        rawType->fields = sSym->type->fields;
      }
    }

    // Get doc for struct itself
    for (const auto& cand : m_candidates) {
      if (cand.name == rawType->name &&
          (cand.kind == "struct" || cand.kind == "union") &&
          !cand.doc.empty()) {
        res.doc = cand.doc;
        break;
      }
    }
    if (res.doc.empty()) {
      res.doc = "Struct '" + rawType->name + "'";
    }

    for (const auto& f : rawType->fields) {
      bool matchPfx = filterPrefix.empty() ||
                      f.name.rfind(filterPrefix, 0) == 0 ||
                      toLower(f.name).rfind(toLower(filterPrefix), 0) == 0;
      if (!matchPfx && !filterPrefix.empty()) {
        matchPfx = (levenshteinDistance(f.name, filterPrefix) <= 2);
      }

      if (matchPfx) {
        std::string fieldDoc;
        for (const auto& cand : m_candidates) {
          if ((cand.name == rawType->name + "." + f.name ||
               cand.name == f.name) &&
              !cand.doc.empty()) {
            fieldDoc = cand.doc;
            break;
          }
        }
        if (fieldDoc.empty()) {
          fieldDoc = "Field '" + f.name + "' of struct " + rawType->name;
        }

        SymbolMember m;
        m.name = f.name;
        m.type = f.type ? f.type->toString() : "unknown";
        m.kind = "field";
        m.signature = f.name + ": " + (f.type ? f.type->toString() : "unknown");
        m.doc = fieldDoc;
        res.members.push_back(m);
      }
    }

    // Add static methods / methods of this struct e.g. Vec2::origin
    std::string smPrefix = rawType->name + "::";
    for (const auto& cand : m_candidates) {
      if (cand.name.rfind(smPrefix, 0) == 0) {
        std::string smName = cand.name.substr(smPrefix.length());
        bool matchPfx = filterPrefix.empty() ||
                        smName.rfind(filterPrefix, 0) == 0 ||
                        toLower(smName).rfind(toLower(filterPrefix), 0) == 0;
        if (!matchPfx && !filterPrefix.empty()) {
          matchPfx = (levenshteinDistance(smName, filterPrefix) <= 2);
        }

        if (matchPfx) {
          bool exists = false;
          for (const auto& em : res.members) {
            if (em.name == smName) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            SymbolMember m;
            m.name = smName;
            m.type = cand.type ? cand.type->toString() : "fn()";
            m.kind = cand.kind;
            m.signature = smPrefix + smName + "()";
            m.doc = cand.doc;
            res.members.push_back(m);
          }
        }
      }
    }

    // Add UFCS / instance-compatible methods where first arg is this type or
    // pointer to it
    for (const auto& fnSymPtr : m_symbolTable.allFunctions()) {
      if (!fnSymPtr || !fnSymPtr->type || !fnSymPtr->type->isFunction())
        continue;
      const auto& pTypes = fnSymPtr->type->paramTypes;
      if (!pTypes.empty()) {
        TypePtr firstArg = pTypes[0];
        TypePtr rawArg =
            firstArg->isPointer() ? firstArg->pointerBase : firstArg;
        if (rawArg && rawArg->name == rawType->name) {
          bool matchPfx =
              filterPrefix.empty() ||
              fnSymPtr->name.rfind(filterPrefix, 0) == 0 ||
              toLower(fnSymPtr->name).rfind(toLower(filterPrefix), 0) == 0;
          if (!matchPfx && !filterPrefix.empty()) {
            matchPfx = (levenshteinDistance(fnSymPtr->name, filterPrefix) <= 2);
          }

          if (matchPfx) {
            bool exists = false;
            for (const auto& em : res.members) {
              if (em.name == fnSymPtr->name) {
                exists = true;
                break;
              }
            }
            if (!exists) {
              SymbolMember m;
              m.name = fnSymPtr->name;
              m.type = fnSymPtr->type->toString();
              m.kind = "method";
              m.signature =
                  fnSymPtr->name + "(" + fnSymPtr->type->toString() + ")";
              m.doc = "UFCS method for " + rawType->name;
              res.members.push_back(m);
            }
          }
        }
      }
    }

    return res;
  }

  // 2. Array or Slice built-in properties
  if (rawType->isArray() || rawType->isSlice()) {
    res.found = true;
    res.kind = rawType->isArray() ? "array" : "slice";

    if (filterPrefix.empty() ||
        std::string("length").rfind(filterPrefix, 0) == 0) {
      SymbolMember m;
      m.name = "length";
      m.type = "ulong";
      m.kind = "property";
      m.signature = "length: ulong";
      m.doc = "Number of elements in array/slice";
      res.members.push_back(m);
    }
    return res;
  }

  // 3. HashMap built-in properties
  if (rawType->isHashMap()) {
    res.found = true;
    res.kind = "hashmap";

    if (filterPrefix.empty() ||
        std::string("length").rfind(filterPrefix, 0) == 0) {
      SymbolMember m;
      m.name = "length";
      m.type = "ulong";
      m.kind = "property";
      m.signature = "length: ulong";
      m.doc = "Number of key-value pairs in hashmap";
      res.members.push_back(m);
    }
    return res;
  }

  // 4. Tuple elements
  if (rawType->isTuple()) {
    res.found = true;
    res.kind = "tuple";
    for (size_t i = 0; i < rawType->tupleElementTypes.size(); ++i) {
      std::string idxStr = std::to_string(i);
      if (filterPrefix.empty() || idxStr.rfind(filterPrefix, 0) == 0) {
        SymbolMember m;
        m.name = idxStr;
        m.type = rawType->tupleElementTypes[i]->toString();
        m.kind = "field";
        m.signature =
            "." + idxStr + ": " + rawType->tupleElementTypes[i]->toString();
        m.doc = "Tuple element at index " + idxStr;
        res.members.push_back(m);
      }
    }
    return res;
  }

  // 5. Universal UFCS / instance-compatible functions for ANY type where first
  // parameter matches rawType
  for (const auto& fnSymPtr : m_symbolTable.allFunctions()) {
    if (!fnSymPtr || !fnSymPtr->type || !fnSymPtr->type->isFunction()) continue;
    const auto& pTypes = fnSymPtr->type->paramTypes;
    if (!pTypes.empty()) {
      TypePtr firstArg = pTypes[0];
      TypePtr rawArg = firstArg->isPointer() ? firstArg->pointerBase : firstArg;
      if (rawArg && (rawArg->name == rawType->name ||
                     (rawArg->kind == rawType->kind &&
                      rawArg->kind == TypeKind::Primitive &&
                      rawArg->name == rawType->name))) {
        bool matchPfx =
            filterPrefix.empty() ||
            fnSymPtr->name.rfind(filterPrefix, 0) == 0 ||
            toLower(fnSymPtr->name).rfind(toLower(filterPrefix), 0) == 0;
        if (!matchPfx && !filterPrefix.empty()) {
          matchPfx = (levenshteinDistance(fnSymPtr->name, filterPrefix) <= 2);
        }

        if (matchPfx) {
          bool exists = false;
          for (const auto& em : res.members) {
            if (em.name == fnSymPtr->name) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            SymbolMember m;
            m.name = fnSymPtr->name;
            m.type = fnSymPtr->type->toString();
            m.kind = "method";
            if (fnSymPtr->funcAST) {
              std::string retStr = fnSymPtr->funcAST->returnTypeAst
                                       ? fnSymPtr->funcAST->returnTypeAst->name
                                       : "void";
              std::string sig = retStr + " " + fnSymPtr->name + "(";
              for (size_t i = 0; i < fnSymPtr->funcAST->parameters.size();
                   ++i) {
                if (i > 0) sig += ", ";
                const auto& p = fnSymPtr->funcAST->parameters[i];
                sig += (p.typeAst ? p.typeAst->name : "auto") + " " + p.name;
              }
              sig += ")";
              m.signature = sig;
            } else {
              m.signature =
                  fnSymPtr->name + "(" + fnSymPtr->type->toString() + ")";
            }
            m.doc = fnSymPtr->funcAST && !fnSymPtr->funcAST->doc.empty()
                        ? fnSymPtr->funcAST->doc
                        : ("UFCS method for " + rawType->name);
            res.members.push_back(m);
          }
        }
      }
    }
  }

  if (!res.members.empty()) {
    res.found = true;
    res.error.clear();
    return res;
  }

  res.found = false;
  res.error =
      "Type '" + rawType->toString() + "' has no accessible members or fields";
  return res;
}

TypePtr SymbolQueryEngine::deduceExpressionType(const std::string& exprStr, int line, int column) {
  if (exprStr.empty()) return nullptr;

  // Split chain by '.' or '->'
  std::vector<std::string> parts;
  std::string current;
  for (size_t i = 0; i < exprStr.size(); ++i) {
    if (exprStr[i] == '.') {
      if (!current.empty()) {
        parts.push_back(current);
        current.clear();
      }
    } else if (i + 1 < exprStr.size() && exprStr[i] == '-' &&
               exprStr[i + 1] == '>') {
      if (!current.empty()) {
        parts.push_back(current);
        current.clear();
      }
      i++;  // skip '>'
    } else if (!isspace(static_cast<unsigned char>(exprStr[i]))) {
      current += exprStr[i];
    }
  }
  if (!current.empty()) {
    parts.push_back(current);
  }

  if (parts.empty()) return nullptr;

  // Resolve root identifier (supports exact and near matching for root
  // variable)
  std::string rootName = parts[0];
  TypePtr curType = nullptr;

  // Check if rootName is a literal value e.g. 10, 3.14, "hello", true
  if (!rootName.empty()) {
    if (std::all_of(rootName.begin(), rootName.end(),
                    [](unsigned char c) { return std::isdigit(c); })) {
      curType = Type::makePrimitive("int");
    } else if (rootName == "true" || rootName == "false") {
      curType = Type::makePrimitive("bool");
    } else if (rootName.front() == '"' || rootName.front() == '\'') {
      curType = Type::makePrimitive("string");
    } else if (rootName.find('.') != std::string::npos) {
      bool allDigitsOrDot = true;
      for (char c : rootName) {
        if (!std::isdigit(static_cast<unsigned char>(c)) && c != '.') {
          allDigitsOrDot = false;
          break;
        }
      }
      if (allDigitsOrDot) curType = Type::makePrimitive("float");
    }
  }

  int bestDist = 100000;
  int bestCandScore = -10000;

  for (const auto& cand : m_candidates) {
    if (!cand.type) continue;
    int score = 0;
    if (cand.name == rootName)
      score = 2000;
    else if (toLower(cand.name) == toLower(rootName))
      score = 1800;
    else if (cand.name.rfind(rootName, 0) == 0)
      score = 1500 - (static_cast<int>(cand.name.length()) -
                      static_cast<int>(rootName.length())) *
                         5;
    else if (toLower(cand.name).rfind(toLower(rootName), 0) == 0)
      score = 1300 - (static_cast<int>(cand.name.length()) -
                      static_cast<int>(rootName.length())) *
                         5;
    else {
      int dist = levenshteinDistance(cand.name, rootName);
      if (dist <= 2) score = 1000 - dist * 100;
    }

    if (score > 0) {
      int lDist =
          (line > 0 && cand.loc.line > 0) ? std::abs(cand.loc.line - line) : 0;
      score -= lDist * 5;
      if (score > bestCandScore) {
        bestCandScore = score;
        curType = cand.type;
      }
    }
  }

  if (!curType) {
    Symbol* varSym = m_symbolTable.lookupVar(rootName);
    if (varSym && varSym->type) curType = varSym->type;
  }
  if (!curType) {
    Symbol* typeSym = m_symbolTable.lookupType(rootName);
    if (typeSym && typeSym->type) curType = typeSym->type;
  }

  if (!curType) return nullptr;

  // Traverse nested fields
  for (size_t p = 1; p < parts.size(); ++p) {
    if (curType->isPointer()) curType = curType->pointerBase;
    if (!curType) return nullptr;

    const std::string& fieldName = parts[p];
    bool foundField = false;

    if (curType->isStruct() || curType->isUnion()) {
      if (curType->fields.empty() && !curType->name.empty()) {
        Symbol* sSym = m_symbolTable.lookupType(curType->name);
        if (sSym && sSym->type) curType->fields = sSym->type->fields;
      }

      for (const auto& f : curType->fields) {
        if (f.name == fieldName || f.name.rfind(fieldName, 0) == 0 ||
            toLower(f.name) == toLower(fieldName)) {
          curType = f.type;
          foundField = true;
          break;
        }
      }
    } else if (curType->isArray() || curType->isSlice()) {
      if (fieldName == "length" ||
          std::string("length").rfind(fieldName, 0) == 0) {
        curType = Type::makePrimitive("ulong");
        foundField = true;
      }
    } else if (curType->isTuple()) {
      try {
        size_t idx = std::stoul(fieldName);
        if (idx < curType->tupleElementTypes.size()) {
          curType = curType->tupleElementTypes[idx];
          foundField = true;
        }
      } catch (...) {
      }
    }

    if (!foundField) return nullptr;
  }

  return curType;
}

SymbolQueryResult SymbolQueryEngine::enumerateExpressionMembers(const std::string& exprStr, const std::string& filterPrefix, int line, int column) {
  TypePtr t = deduceExpressionType(exprStr, line, column);
  if (!t) {
    SymbolQueryResult err;
    err.found = false;
    err.name = exprStr;
    err.error = "Could not deduce type of expression '" + exprStr + "'";
    return err;
  }
  auto res = enumerateTypeMembers(t, filterPrefix);
  res.name = exprStr;
  return res;
}

SymbolQueryResult SymbolQueryEngine::query(const std::string& file, int line, int column, const std::string& symbolName) {
  SymbolQueryResult result;
  result.file = file;
  result.line = line;
  result.column = column;

  std::string targetSymbol = symbolName;

  // Explicit Scoped query passed e.g. "Foo::Bar", "Foo::", "Days::Mon"
  if (!targetSymbol.empty() && targetSymbol.find("::") != std::string::npos) {
    if (targetSymbol.rfind("::") == targetSymbol.length() - 2) {
      std::string scope = targetSymbol.substr(0, targetSymbol.length() - 2);
      return enumerateScope(scope, "");
    }
    return queryScopedSymbol(targetSymbol);
  }

  // Explicit Field query passed e.g. "v.", "v.x", "point.x"
  if (!targetSymbol.empty() && (targetSymbol.find('.') != std::string::npos ||
                                targetSymbol.find("->") != std::string::npos)) {
    if (targetSymbol.back() == '.') {
      std::string expr = targetSymbol.substr(0, targetSymbol.length() - 1);
      return enumerateExpressionMembers(expr, "", line, column);
    }
    size_t lastDot = targetSymbol.rfind('.');
    if (lastDot != std::string::npos) {
      std::string expr = targetSymbol.substr(0, lastDot);
      std::string fPrefix = targetSymbol.substr(lastDot + 1);
      auto memRes = enumerateExpressionMembers(expr, fPrefix, line, column);
      if (!fPrefix.empty() && !memRes.members.empty()) {
        // Return best matching member as direct result
        const auto& m0 = memRes.members[0];
        result.found = true;
        result.name = m0.name;
        result.type = m0.type;
        result.kind = m0.kind;
        result.doc = m0.doc;
        result.members = memRes.members;
        return result;
      }
      return memRes;
    }
  }

  // Smart context inference from tokens leading up to (line, column)
  if (targetSymbol.empty() && line > 0 && column > 0) {
    std::vector<Token> lineTokens;
    for (const auto& tok : m_tokens) {
      if (tok.loc.line == line && tok.loc.column <= column + 1) {
        lineTokens.push_back(tok);
      }
    }

    if (!lineTokens.empty()) {
      const auto& lastTok = lineTokens.back();

      // Cursor is right after '::' -> Scope Enumeration e.g. `Foo::`
      if (lastTok.lexeme == "::" || lastTok.kind == TokenKind::DoubleColon) {
        if (lineTokens.size() >= 2) {
          const auto& prevTok = lineTokens[lineTokens.size() - 2];
          if (prevTok.kind == TokenKind::Identifier) {
            return enumerateScope(prevTok.lexeme, "");
          }
        }
      }

      // Cursor is right after '.' -> Member Enumeration e.g. `v.` or
      // `point.`
      if (lastTok.lexeme == "." || lastTok.kind == TokenKind::Dot) {
        std::string chain;
        for (int i = static_cast<int>(lineTokens.size()) - 2; i >= 0; --i) {
          if (lineTokens[i].kind == TokenKind::Identifier ||
              lineTokens[i].kind == TokenKind::Dot) {
            chain = lineTokens[i].lexeme + chain;
          } else {
            break;
          }
        }
        if (!chain.empty()) {
          return enumerateExpressionMembers(chain, "", line, column);
        }
      }

      // Cursor is currently typing after '::' e.g. `Days::Mon` or
      // `Vec2::orig`
      if (lineTokens.size() >= 3) {
        const auto& colTok = lineTokens[lineTokens.size() - 2];
        const auto& scopeTok = lineTokens[lineTokens.size() - 3];
        if ((colTok.lexeme == "::" || colTok.kind == TokenKind::DoubleColon) &&
            scopeTok.kind == TokenKind::Identifier) {
          if (lastTok.kind == TokenKind::Identifier) {
            return queryScopedSymbol(scopeTok.lexeme + "::" + lastTok.lexeme);
          }
        }
      }

      // Cursor is currently typing after '.' e.g. `v.x` or `10.add`
      if (lineTokens.size() >= 3) {
        const auto& dotTok = lineTokens[lineTokens.size() - 2];
        if (dotTok.lexeme == "." || dotTok.kind == TokenKind::Dot) {
          std::string chain;
          for (int i = static_cast<int>(lineTokens.size()) - 3; i >= 0; --i) {
            if (lineTokens[i].kind == TokenKind::Identifier ||
                lineTokens[i].kind == TokenKind::Dot ||
                lineTokens[i].kind == TokenKind::IntegerLiteral ||
                lineTokens[i].kind == TokenKind::FloatLiteral ||
                lineTokens[i].kind == TokenKind::StringLiteral) {
              chain = lineTokens[i].lexeme + chain;
            } else {
              break;
            }
          }
          if (!chain.empty() && lastTok.kind == TokenKind::Identifier) {
            auto memRes =
                enumerateExpressionMembers(chain, lastTok.lexeme, line, column);
            if (!memRes.members.empty()) {
              const auto& m0 = memRes.members[0];
              result.found = true;
              result.name = m0.name;
              result.type = m0.type;
              result.kind = m0.kind;
              result.doc = m0.doc;
              result.signature = m0.signature;
              auto fnSyms = m_symbolTable.lookupFunctions(m0.name);
              if (!fnSyms.empty() && fnSyms[0]->funcAST) {
                result.declLine = fnSyms[0]->funcAST->loc.line;
                result.declColumn = fnSyms[0]->funcAST->loc.column;
              }
              result.members = memRes.members;
              return result;
            }
            return memRes;
          }
        }
      }

      // Check token at or inside or at end of (line, column)
      for (const auto& tok : lineTokens) {
        int sCol = tok.loc.column;
        int eCol = sCol + static_cast<int>(tok.lexeme.length());
        if (column >= sCol && column <= eCol + 1) {
          bool isIdentOrKw = (tok.kind == TokenKind::Identifier) ||
                             (tok.kind >= TokenKind::KwImport &&
                              tok.kind <= TokenKind::KwContinue);
          if (isIdentOrKw) {
            targetSymbol = tok.lexeme;
            break;
          }
        }
      }
    }
  }

  // Search candidates using near-match scoring
  const Candidate* bestMatch = nullptr;
  int highestScore = -100000;
  bool foundCandidate = false;

  for (const auto& cand : m_candidates) {
    // If candidate is a function parameter, ignore it if cursor line is outside
    // the function's scope!
    if (cand.kind == "parameter" && cand.scopeStart.line > 0) {
      if (line < cand.scopeStart.line ||
          (cand.scopeEnd.line > 0 && line > cand.scopeEnd.line)) {
        continue;
      }
    }

    int score = 0;

    // Proximity to line
    if (cand.loc.line > 0 && line > 0) {
      int lineDist = std::abs(cand.loc.line - line);
      if (lineDist == 0) {
        score += 400;
        int colDist = std::abs(cand.loc.column - column);
        if (colDist == 0)
          score += 300;
        else if (colDist <= static_cast<int>(cand.name.length()))
          score += 200 - colDist * 10;
        else
          score -= colDist * 5;
      } else if (cand.loc.line <= line) {
        // Declared before current line in scope
        score += 200 - (std::min)(lineDist, 20) * 5;
      } else {
        score -= lineDist * 10;
      }
    }

    // Symbol name / near-match scoring
    if (!targetSymbol.empty()) {
      std::string q = targetSymbol;
      std::string cName = cand.name;

      // Strip scope or dot prefix for short matching if present
      std::string shortCand = cName;
      size_t sepPos = shortCand.rfind("::");
      if (sepPos != std::string::npos) shortCand = shortCand.substr(sepPos + 2);
      size_t dotPos = shortCand.rfind(".");
      if (dotPos != std::string::npos) shortCand = shortCand.substr(dotPos + 1);

      if (cName == q || shortCand == q) {
        score += 2000;
      } else if (toLower(cName) == toLower(q) ||
                 toLower(shortCand) == toLower(q)) {
        score += 1800;
      } else if (cName.rfind(q, 0) == 0 || shortCand.rfind(q, 0) == 0) {
        score += 1500 - (static_cast<int>(shortCand.length()) -
                         static_cast<int>(q.length())) *
                            5;
      } else if (toLower(cName).rfind(toLower(q), 0) == 0 ||
                 toLower(shortCand).rfind(toLower(q), 0) == 0) {
        score += 1300 - (static_cast<int>(shortCand.length()) -
                         static_cast<int>(q.length())) *
                            5;
      } else if (shortCand.find(q) != std::string::npos) {
        score += 1000 - (static_cast<int>(shortCand.length()) -
                         static_cast<int>(q.length())) *
                            5;
      } else {
        int dist = levenshteinDistance(shortCand, q);
        if (dist <= 2) {
          score += 900 - dist * 150;
        } else {
          score -= 500;
        }
      }
    }

    // Known type preference
    if (cand.type && cand.type->kind != TypeKind::Unknown &&
        cand.type->kind != TypeKind::Error) {
      score += 100;
    }

    if (score > highestScore) {
      highestScore = score;
      bestMatch = &cand;
      foundCandidate = true;
    }
  }

  if (foundCandidate && (highestScore > 0 || !targetSymbol.empty())) {
    result.found = true;
    result.name = bestMatch->name;
    result.type = bestMatch->type ? bestMatch->type->toString() : "unknown";
    result.kind = bestMatch->kind;
    result.line = bestMatch->loc.line > 0 ? bestMatch->loc.line : line;
    result.column = bestMatch->loc.column > 0 ? bestMatch->loc.column : column;
    result.doc = bestMatch->doc;
    result.signature = bestMatch->signature;
    if (result.signature.empty() &&
        (result.kind == "function" || result.kind == "static_method" ||
         result.kind == "method")) {
      auto fnSyms = m_symbolTable.lookupFunctions(result.name);
      if (!fnSyms.empty() && fnSyms[0]->funcAST) {
        const auto& fAST = fnSyms[0]->funcAST;
        std::string retStr =
            fAST->returnTypeAst ? fAST->returnTypeAst->name : "void";
        std::string sig = retStr + " " + result.name + "(";
        for (size_t i = 0; i < fAST->parameters.size(); ++i) {
          if (i > 0) sig += ", ";
          const auto& p = fAST->parameters[i];
          sig += (p.typeAst ? p.typeAst->name : "auto") + " " + p.name;
        }
        sig += ")";
        result.signature = sig;
      }
    }
    if (!bestMatch->loc.filename.empty()) {
      result.file = bestMatch->loc.filename;
    }
    if (bestMatch->declLoc.line > 0) {
      result.declLine = bestMatch->declLoc.line;
      result.declColumn = bestMatch->declLoc.column;
    }

    // If this resolved symbol is a struct, union, or enum, attach its members
    // automatically!
    if (bestMatch->type) {
      if (bestMatch->type->isStruct() || bestMatch->type->isUnion() ||
          bestMatch->type->isEnum()) {
        auto memberQuery = bestMatch->type->isEnum()
                               ? enumerateScope(bestMatch->name)
                               : enumerateTypeMembers(bestMatch->type);
        result.members = memberQuery.members;
      }
    }

    return result;
  }

  // Step 5: Fallback lookup directly into SymbolTable with near-matching
  if (!targetSymbol.empty()) {
    Symbol* varSym = m_symbolTable.lookupVar(targetSymbol);
    if (varSym && varSym->type) {
      result.found = true;
      result.name = targetSymbol;
      result.type = varSym->type->toString();
      result.kind = varSym->isConst ? "constant" : "variable";
      if (varSym->type->isStruct() || varSym->type->isUnion()) {
        auto mRes = enumerateTypeMembers(varSym->type);
        result.members = mRes.members;
      }
      return result;
    }

    auto fnSyms = m_symbolTable.lookupFunctions(targetSymbol);
    if (!fnSyms.empty() && fnSyms[0]->type) {
      result.found = true;
      result.name = targetSymbol;
      result.type = fnSyms[0]->type->toString();
      result.kind = "function";
      return result;
    }

    Symbol* typeSym = m_symbolTable.lookupType(targetSymbol);
    if (typeSym && typeSym->type) {
      result.found = true;
      result.name = targetSymbol;
      result.type = typeSym->type->toString();
      result.kind = typeSym->type->isStruct()  ? "struct"
                    : typeSym->type->isUnion() ? "union"
                    : typeSym->type->isEnum()  ? "enum"
                                               : "type";
      auto mRes = typeSym->type->isEnum() ? enumerateScope(targetSymbol)
                                          : enumerateTypeMembers(typeSym->type);
      result.members = mRes.members;
      return result;
    }
  }

  result.found = false;
  result.name = targetSymbol;
  result.type = "unknown";
  result.kind = "unknown";
  result.error = "Symbol not found at line " + std::to_string(line) +
                 ", column " + std::to_string(column);
  return result;
}

}  // namespace Glang
