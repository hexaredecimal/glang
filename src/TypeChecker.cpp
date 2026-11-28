#include "compiler/TypeChecker.hpp"
#include "compiler/Lexer.hpp"
#include "compiler/Parser.hpp"
#include <fstream>
#include <algorithm>
#include <iostream>
#include <functional>

namespace Glang {

static TypeASTPtr makeTypeASTFromType(TypePtr type, const Location& loc) {
  if (!type) return std::make_shared<TypeASTNode>(loc, "void");

  if (type->kind == TypeKind::Alias && type->aliasTarget) {
    return makeTypeASTFromType(type->aliasTarget, loc);
  }

  auto node = std::make_shared<TypeASTNode>(loc, type->name);
  node->isConst = type->isConst;

  if (type->isPointer()) {
    node->isPointer = true;
    node->pointerBase = makeTypeASTFromType(type->pointerBase, loc);
  } else if (type->isArray()) {
    node->isArray = true;
    node->arraySize = type->arraySize;
    node->elementType = makeTypeASTFromType(type->elementType, loc);
  } else if (type->isSlice()) {
    node->isSlice = true;
    node->elementType = makeTypeASTFromType(type->elementType, loc);
  } else if (type->isHashMap()) {
    node->isMap = true;
    node->keyType = makeTypeASTFromType(type->keyType, loc);
    node->elementType = makeTypeASTFromType(type->elementType, loc);
  } else if (type->isTuple()) {
    node->isTuple = true;
    for (const auto& elem : type->tupleElementTypes) {
      node->tupleElementTypes.push_back(makeTypeASTFromType(elem, loc));
    }
  } else if (type->isFunction() || type->isClosure()) {
    node->isFunctionType = true;
    node->isFunctionPointer = type->isFunctionPointer;
    for (const auto& p : type->paramTypes) {
      node->paramTypes.push_back(makeTypeASTFromType(p, loc));
    }
    node->returnType = makeTypeASTFromType(type->returnType, loc);
  } else {
    for (const auto& arg : type->typeArgs) {
      node->templateArgs.push_back(makeTypeASTFromType(arg, loc));
    }
  }

  return node;
}

static TypeASTPtr cloneTypeAST(const TypeASTPtr& type);
static ExprPtr cloneExpr(const ExprPtr& expr);
static StmtPtr cloneStmt(const StmtPtr& stmt);

static void copyNodeMetadata(const ASTNode& source, ASTNode& target) {
  target.inferredType = source.inferredType;
  target.doc = source.doc;
}

static std::vector<Attribute> cloneAttributes(
    const std::vector<Attribute>& attributes) {
  auto copy = attributes;
  for (auto& attribute : copy) {
    for (auto& argument : attribute.args) {
      argument.value = cloneExpr(argument.value);
    }
  }
  return copy;
}

static TypeASTPtr cloneTypeAST(const TypeASTPtr& type) {
  if (!type) return nullptr;
  auto copy = std::make_shared<TypeASTNode>(type->loc, type->name);
  copyNodeMetadata(*type, *copy);
  copy->resolvedName = type->resolvedName;
  copy->isPointer = type->isPointer;
  copy->isConst = type->isConst;
  copy->isArray = type->isArray;
  copy->isSlice = type->isSlice;
  copy->isMap = type->isMap;
  copy->isRuntimeSizedArray = type->isRuntimeSizedArray;
  copy->isAmbiguousArrayOrMap = type->isAmbiguousArrayOrMap;
  copy->isTuple = type->isTuple;
  copy->isFunctionType = type->isFunctionType;
  copy->isFunctionPointer = type->isFunctionPointer;
  copy->declName = type->declName;
  copy->arraySize = type->arraySize;
  copy->pointerBase = cloneTypeAST(type->pointerBase);
  copy->elementType = cloneTypeAST(type->elementType);
  copy->keyType = cloneTypeAST(type->keyType);
  copy->arraySizeExpr = cloneExpr(type->arraySizeExpr);
  copy->returnType = cloneTypeAST(type->returnType);
  for (const auto& arg : type->templateArgs)
    copy->templateArgs.push_back(cloneTypeAST(arg));
  for (const auto& elem : type->tupleElementTypes)
    copy->tupleElementTypes.push_back(cloneTypeAST(elem));
  for (const auto& param : type->paramTypes)
    copy->paramTypes.push_back(cloneTypeAST(param));
  return copy;
}

static ExprPtr cloneExpr(const ExprPtr& expr) {
  if (!expr) return nullptr;
  ExprPtr copy;
  if (auto node = std::dynamic_pointer_cast<TupleLiteralExprAST>(expr)) {
    std::vector<ExprPtr> elements;
    for (const auto& element : node->elements) elements.push_back(cloneExpr(element));
    copy = std::make_shared<TupleLiteralExprAST>(node->loc, std::move(elements));
  } else if (auto node = std::dynamic_pointer_cast<ArrayLiteralExprAST>(expr)) {
    std::vector<ExprPtr> elements;
    for (const auto& element : node->elements) elements.push_back(cloneExpr(element));
    copy = std::make_shared<ArrayLiteralExprAST>(node->loc, std::move(elements));
  } else if (auto node = std::dynamic_pointer_cast<MapLiteralExprAST>(expr)) {
    std::vector<std::pair<ExprPtr, ExprPtr>> entries;
    for (const auto& entry : node->entries)
      entries.emplace_back(cloneExpr(entry.first), cloneExpr(entry.second));
    copy = std::make_shared<MapLiteralExprAST>(node->loc, std::move(entries));
  } else if (auto node = std::dynamic_pointer_cast<IndexExprAST>(expr)) {
    copy = std::make_shared<IndexExprAST>(node->loc, cloneExpr(node->target),
                                          cloneExpr(node->index));
  } else if (auto node = std::dynamic_pointer_cast<SliceExprAST>(expr)) {
    copy = std::make_shared<SliceExprAST>(
        node->loc, cloneExpr(node->target), cloneExpr(node->startExpr),
        cloneExpr(node->endExpr));
  } else if (auto node = std::dynamic_pointer_cast<IntegerLiteralExprAST>(expr)) {
    copy = std::make_shared<IntegerLiteralExprAST>(node->loc, node->value);
  } else if (auto node = std::dynamic_pointer_cast<FloatLiteralExprAST>(expr)) {
    copy = std::make_shared<FloatLiteralExprAST>(node->loc, node->value);
  } else if (auto node = std::dynamic_pointer_cast<StringLiteralExprAST>(expr)) {
    copy = std::make_shared<StringLiteralExprAST>(node->loc, node->value);
  } else if (auto node = std::dynamic_pointer_cast<CharLiteralExprAST>(expr)) {
    copy = std::make_shared<CharLiteralExprAST>(node->loc, node->value);
  } else if (auto node = std::dynamic_pointer_cast<BoolLiteralExprAST>(expr)) {
    copy = std::make_shared<BoolLiteralExprAST>(node->loc, node->value);
  } else if (auto node = std::dynamic_pointer_cast<NullLiteralExprAST>(expr)) {
    copy = std::make_shared<NullLiteralExprAST>(node->loc);
  } else if (auto node = std::dynamic_pointer_cast<IdentifierExprAST>(expr)) {
    copy = std::make_shared<IdentifierExprAST>(node->loc, node->name);
  } else if (auto node = std::dynamic_pointer_cast<ScopedIdentifierExprAST>(expr)) {
    copy = std::make_shared<ScopedIdentifierExprAST>(
        node->loc, node->scopeName, node->memberName);
  } else if (auto node = std::dynamic_pointer_cast<BinaryExprAST>(expr)) {
    auto cloned = std::make_shared<BinaryExprAST>(
        node->loc, node->op, cloneExpr(node->left), cloneExpr(node->right));
    cloned->targetMangledName = node->targetMangledName;
    cloned->targetParamTypes = node->targetParamTypes;
    cloned->targetReturnType = node->targetReturnType;
    cloned->isOverloadedOperator = node->isOverloadedOperator;
    copy = std::move(cloned);
  } else if (auto node = std::dynamic_pointer_cast<UnaryExprAST>(expr)) {
    if (node->typeOperand)
      copy = std::make_shared<UnaryExprAST>(node->loc, node->op,
                                            cloneTypeAST(node->typeOperand));
    else
      copy = std::make_shared<UnaryExprAST>(node->loc, node->op,
                                            cloneExpr(node->operand));
    if (auto cloned = std::dynamic_pointer_cast<UnaryExprAST>(copy)) {
      cloned->targetMangledName = node->targetMangledName;
      cloned->targetParamTypes = node->targetParamTypes;
      cloned->targetReturnType = node->targetReturnType;
      cloned->isOverloadedOperator = node->isOverloadedOperator;
    }
  } else if (auto node = std::dynamic_pointer_cast<PostfixUnaryExprAST>(expr)) {
    if (node->typeOperand)
      copy = std::make_shared<PostfixUnaryExprAST>(
          node->loc, node->op, cloneTypeAST(node->typeOperand));
    else
      copy = std::make_shared<PostfixUnaryExprAST>(node->loc, node->op,
                                                   cloneExpr(node->operand));
    if (auto cloned = std::dynamic_pointer_cast<PostfixUnaryExprAST>(copy)) {
      cloned->targetMangledName = node->targetMangledName;
      cloned->targetParamTypes = node->targetParamTypes;
      cloned->targetReturnType = node->targetReturnType;
      cloned->isOverloadedOperator = node->isOverloadedOperator;
    }
  } else if (auto node = std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) {
    copy = std::make_shared<MemberAccessExprAST>(
        node->loc, cloneExpr(node->object), node->memberName,
        node->isPointerArrow);
  } else if (auto node = std::dynamic_pointer_cast<CallExprAST>(expr)) {
    std::vector<TypeASTPtr> templateArgs;
    std::vector<ExprPtr> arguments;
    for (const auto& arg : node->templateArgs)
      templateArgs.push_back(cloneTypeAST(arg));
    for (const auto& arg : node->arguments) arguments.push_back(cloneExpr(arg));
    auto cloned = std::make_shared<CallExprAST>(
        node->loc, cloneExpr(node->callee), std::move(templateArgs),
        std::move(arguments));
    cloned->isUserLiteral = node->isUserLiteral;
    cloned->literalSuffix = node->literalSuffix;
    cloned->operatorKind = node->operatorKind;
    cloned->usesBuiltinOperator = node->usesBuiltinOperator;
    cloned->targetMangledName = node->targetMangledName;
    cloned->targetParamTypes = node->targetParamTypes;
    cloned->targetReturnType = node->targetReturnType;
    cloned->targetVariadic = node->targetVariadic;
    copy = std::move(cloned);
  } else if (auto node = std::dynamic_pointer_cast<StaticMethodCallExprAST>(expr)) {
    std::vector<TypeASTPtr> templateArgs;
    std::vector<ExprPtr> arguments;
    for (const auto& arg : node->templateArgs)
      templateArgs.push_back(cloneTypeAST(arg));
    for (const auto& arg : node->arguments) arguments.push_back(cloneExpr(arg));
    auto cloned = std::make_shared<StaticMethodCallExprAST>(
        node->loc, node->targetType, node->methodName, std::move(templateArgs),
        std::move(arguments));
    cloned->targetMangledName = node->targetMangledName;
    cloned->targetParamTypes = node->targetParamTypes;
    cloned->targetReturnType = node->targetReturnType;
    copy = std::move(cloned);
  } else if (auto node = std::dynamic_pointer_cast<StructInitExprAST>(expr)) {
    std::vector<std::pair<std::string, ExprPtr>> fields;
    for (const auto& field : node->fieldInits)
      fields.emplace_back(field.first, cloneExpr(field.second));
    copy = std::make_shared<StructInitExprAST>(
        node->loc, cloneTypeAST(node->structType), std::move(fields));
  } else if (auto node = std::dynamic_pointer_cast<YieldExprAST>(expr)) {
    copy = std::make_shared<YieldExprAST>(node->loc,
                                          cloneExpr(node->yieldedExpr));
  } else if (auto node = std::dynamic_pointer_cast<BlockExprAST>(expr)) {
    std::vector<StmtPtr> statements;
    for (const auto& statement : node->statements)
      statements.push_back(cloneStmt(statement));
    copy = std::make_shared<BlockExprAST>(
        node->loc, std::move(statements), cloneExpr(node->yieldExpr));
  } else if (auto node = std::dynamic_pointer_cast<IfExprAST>(expr)) {
    copy = std::make_shared<IfExprAST>(
        node->loc, cloneExpr(node->condition), cloneExpr(node->thenBranch),
        cloneExpr(node->elseBranch));
  } else if (auto node = std::dynamic_pointer_cast<SwitchExprAST>(expr)) {
    std::vector<SwitchCase> cases;
    for (const auto& item : node->cases)
      cases.push_back({cloneExpr(item.pattern), cloneExpr(item.rangeEnd),
                       cloneExpr(item.body)});
    copy = std::make_shared<SwitchExprAST>(
        node->loc, cloneExpr(node->targetExpr), std::move(cases));
  } else if (auto node = std::dynamic_pointer_cast<ClosureExprAST>(expr)) {
    std::vector<ClosureParam> params = node->params;
    for (auto& param : params) param.typeAst = cloneTypeAST(param.typeAst);
    copy = std::make_shared<ClosureExprAST>(
        node->loc, std::move(params), cloneTypeAST(node->returnTypeAst),
        cloneExpr(node->body));
  } else if (auto node = std::dynamic_pointer_cast<AssignExprAST>(expr)) {
    copy = std::make_shared<AssignExprAST>(
        node->loc, cloneExpr(node->target), cloneExpr(node->value), node->op);
  } else if (auto node = std::dynamic_pointer_cast<CastExprAST>(expr)) {
    copy = std::make_shared<CastExprAST>(
        node->loc, cloneExpr(node->expr), cloneTypeAST(node->targetTypeAst));
  }
  if (copy) copyNodeMetadata(*expr, *copy);
  return copy ? copy : expr;
}

static StmtPtr cloneStmt(const StmtPtr& stmt) {
  if (!stmt) return nullptr;
  StmtPtr copy;
  if (auto node = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
    auto cloned = std::make_shared<VarDeclStmtAST>(
        node->loc, node->name, cloneTypeAST(node->typeAst),
        cloneExpr(node->initializer), node->isConst, node->isStatic);
    cloned->attributes = cloneAttributes(node->attributes);
    copy = std::move(cloned);
  } else if (auto node = std::dynamic_pointer_cast<StructuralBindingStmtAST>(stmt)) {
    auto cloned = std::make_shared<StructuralBindingStmtAST>(
        node->loc, node->symbols, cloneTypeAST(node->typeAst),
        cloneExpr(node->initializer), node->isConst, node->isStatic);
    cloned->attributes = cloneAttributes(node->attributes);
    copy = std::move(cloned);
  } else if (auto node = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
    copy = std::make_shared<ExprStmtAST>(node->loc, cloneExpr(node->expr));
  } else if (auto node = std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
    copy = std::make_shared<ReturnStmtAST>(node->loc, cloneExpr(node->value));
  } else if (auto node = std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
    copy = std::make_shared<YieldStmtAST>(node->loc, cloneExpr(node->value));
  } else if (std::dynamic_pointer_cast<BreakStmtAST>(stmt)) {
    copy = std::make_shared<BreakStmtAST>(stmt->loc);
  } else if (std::dynamic_pointer_cast<ContinueStmtAST>(stmt)) {
    copy = std::make_shared<ContinueStmtAST>(stmt->loc);
  } else if (auto node = std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
    copy = std::make_shared<DeferStmtAST>(node->loc,
                                          cloneStmt(node->deferredStmt));
  } else if (auto node = std::dynamic_pointer_cast<ImportStmtAST>(stmt)) {
    copy = std::make_shared<ImportStmtAST>(node->loc, node->items);
  } else if (auto node = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
    copy = std::make_shared<WhileStmtAST>(
        node->loc, cloneExpr(node->condition), cloneStmt(node->body));
  } else if (auto node = std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
    copy = std::make_shared<DoWhileStmtAST>(
        node->loc, cloneStmt(node->body), cloneExpr(node->condition));
  } else if (auto node = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
    copy = std::make_shared<ForStmtAST>(
        node->loc, cloneStmt(node->init), cloneExpr(node->condition),
        cloneExpr(node->post), cloneStmt(node->body));
  } else if (auto node = std::dynamic_pointer_cast<TypeAliasStmtAST>(stmt)) {
    std::shared_ptr<TypeAliasDeclAST> alias;
    if (node->decl) {
      alias = std::make_shared<TypeAliasDeclAST>(
          node->decl->loc, node->decl->aliasName, node->decl->typeParams,
          cloneTypeAST(node->decl->targetTypeAst));
      alias->attributes = cloneAttributes(node->decl->attributes);
      copyNodeMetadata(*node->decl, *alias);
    }
    copy = std::make_shared<TypeAliasStmtAST>(node->loc, std::move(alias));
  }
  if (copy) copyNodeMetadata(*stmt, *copy);
  return copy ? copy : stmt;
}

static bool hasAttribute(const std::vector<Attribute>& attrs, const std::string& name) {
  for (const auto& a : attrs) {
    if (a.name == name) return true;
  }
  return false;
}

static TypePtr normalizeVariadicParameterType(TypePtr type) {
  if (!type) return nullptr;
  if (type->isArray() || type->isSlice()) {
    return Type::makeSlice(type->elementType);
  }
  return Type::makeSlice(type);
}

static bool isExternFunction(const FunctionDeclAST* function) {
  return function &&
         (!function->body || hasAttribute(function->attributes, "extern"));
}

std::string TypeChecker::qualifyImportedFunctionName(
    const FunctionDeclAST& function, const std::string& name) const {
  const std::string& module = function.loc.filename;
  if (module.empty() ||
      (m_activeImports.count(module) == 0 &&
       m_importedModules.count(module) == 0)) {
    return name;
  }
  return "_glang_" + module + "_" + name;
}

static std::string getExternLinkName(const std::vector<Attribute>& attrs) {
  for (const auto& a : attrs) {
    if (a.name == "link_name" || a.name == "extern") {
      for (const auto& arg : a.args) {
        if (auto strLit =
                std::dynamic_pointer_cast<StringLiteralExprAST>(arg.value)) {
          return strLit->value;
        }
      }
    }
  }
  return "";
}

TypeChecker::TypeChecker() {}

void TypeChecker::registerModuleSource(const std::string& moduleName, const std::string& sourceCode) {
  m_virtualModuleSources[moduleName] = sourceCode;
}

void TypeChecker::error(const Location& loc, const std::string& msg, const std::string& token) {
  for (const auto& existing : m_result.errors) {
    if (existing.filename == loc.filename && existing.line == loc.line &&
        existing.column == loc.column && existing.message == msg &&
        existing.token == token) {
      return;
    }
  }
  m_result.errors.emplace_back(loc, msg, token);
}

TypePtr TypeChecker::resolveTypeAST(TypeASTPtr ast) {
  if (!ast) return Type::makeUnknown();

  if (ast->isAmbiguousArrayOrMap && ast->keyType) {
    Symbol* keySymbol = m_symbolTable.lookupType(ast->keyType->name);
    if (keySymbol && keySymbol->isType) {
      ast->isAmbiguousArrayOrMap = false;
      ast->isRuntimeSizedArray = false;
      ast->isArray = false;
      ast->isMap = true;
      return Type::makeHashMap(resolveTypeAST(ast->keyType),
                               resolveTypeAST(ast->elementType));
    }
    ast->isAmbiguousArrayOrMap = false;
  }
  if (ast->isRuntimeSizedArray) {
    return Type::makeSlice(resolveTypeAST(ast->elementType));
  }
  if (ast->isPointer) {
    auto baseType = resolveTypeAST(ast->pointerBase);
    return Type::makePointer(baseType, ast->isConst);
  }
  if (ast->isArray) {
    auto elemType = resolveTypeAST(ast->elementType);
    return Type::makeArray(elemType, ast->arraySize);
  }
  if (ast->isSlice) {
    auto elemType = resolveTypeAST(ast->elementType);
    return Type::makeSlice(elemType);
  }
  if (ast->isMap) {
    auto keyType = resolveTypeAST(ast->keyType);
    auto valType = resolveTypeAST(ast->elementType);
    return Type::makeHashMap(keyType, valType);
  }
  if (ast->isTuple) {
    std::vector<TypePtr> elems;
    for (const auto& eAst : ast->tupleElementTypes) {
      elems.push_back(resolveTypeAST(eAst));
    }
    auto t = Type::makeTuple(elems);
    t->isConst = ast->isConst;
    return t;
  }
  if (ast->isFunctionType) {
    std::vector<TypePtr> params;
    for (const auto& pAst : ast->paramTypes) {
      params.push_back(resolveTypeAST(pAst));
    }
    TypePtr ret = ast->returnType ? resolveTypeAST(ast->returnType)
                                  : Type::makePrimitive("void");
    auto f = Type::makeFunction(params, ret);
    f->isConst = ast->isConst;
    f->isFunctionPointer = ast->isFunctionPointer;
    return f;
  }

  Symbol* sym = m_symbolTable.lookupType(ast->name);
  if (ast->name.find("::") != std::string::npos) {
    size_t pos = ast->name.rfind("::");
    std::string prefix = ast->name.substr(0, pos);
    std::string member = ast->name.substr(pos + 2);

    Symbol* pSym = m_symbolTable.lookupType(prefix);
    TypePtr pType = nullptr;
    if (pSym && pSym->type) {
      pType = pSym->type->underlyingType();
      if (pType && !ast->templateArgs.empty() &&
          (pType->isStruct() || pType->isUnion())) {
        std::vector<TypePtr> typeArgs;
        for (const auto& argAst : ast->templateArgs) {
          typeArgs.push_back(resolveTypeAST(argAst));
        }
        pType = pType->isStruct()
                    ? Type::makeStruct(pType->name, typeArgs)
                    : Type::makeUnion(pType->name, typeArgs);
      }
    } else {
      size_t anglePos = prefix.find("<");
      if (anglePos != std::string::npos && prefix.back() == '>') {
        std::string baseName = prefix.substr(0, anglePos);
        std::string argsStr = prefix.substr(anglePos + 1, prefix.size() - anglePos - 2);
        Symbol* baseSym = m_symbolTable.lookupType(baseName);
        if (baseSym && baseSym->type) {
          std::vector<TypePtr> tArgs;
          Symbol* argSym = m_symbolTable.lookupType(argsStr);
          if (argSym && argSym->type) {
            tArgs.push_back(argSym->type);
          } else {
            tArgs.push_back(Type::makePrimitive(argsStr));
          }
          pType = Type::makeStruct(baseName, tArgs);
          instantiateType(pType, ast->loc);
        }
      }
    }

    if (pType) {
      if (pType->isGenericParam()) {
        return Type::makeGenericParam(ast->name);
      }
      std::string qName = pType->name + "::" + member;
      Symbol* memberSym = m_symbolTable.lookupType(qName);
      if (!memberSym) {
        memberSym = m_symbolTable.lookupType(pType->toString() + "::" + member);
      }
      auto ownerDecl = m_allStructDecls.find(pType->name);
      std::shared_ptr<TypeAliasDeclAST> internalAlias;
      if (ownerDecl != m_allStructDecls.end() && ownerDecl->second) {
        for (const auto& alias : ownerDecl->second->typeAliases) {
          if (alias && alias->aliasName == member) {
            internalAlias = alias;
            break;
          }
        }
      }

      if (internalAlias && pType->isStruct()) {
        m_symbolTable.enterScope();
        for (size_t i = 0;
             i < ownerDecl->second->typeParams.size() &&
             i < pType->typeArgs.size();
             ++i) {
          m_symbolTable.defineType(ownerDecl->second->typeParams[i],
                                  pType->typeArgs[i]);
        }
        for (size_t i = 0;
             i < internalAlias->typeParams.size() &&
             i < ast->templateArgs.size();
             ++i) {
          m_symbolTable.defineType(internalAlias->typeParams[i],
                                   resolveTypeAST(ast->templateArgs[i]));
        }
        TypePtr resolved = resolveTypeAST(internalAlias->targetTypeAst);
        m_symbolTable.exitScope();
        if (resolved && resolved->kind != TypeKind::Error) {
          return Type::makeAlias(pType->toString() + "::" + member,
                                 resolved);
        }
        return Type::makeError();
      } else if (memberSym) {
        sym = memberSym;
      }

      if (!sym) {
        error(ast->loc, "Type '" + pType->toString() + "' has no member or inner type named '" + member + "'");
        return Type::makeError();
      }
    }
  }

  if (!sym) {
    std::vector<TypePtr> resolvedArgs;
    for (const auto& argAst : ast->templateArgs) {
      resolvedArgs.push_back(resolveTypeAST(argAst));
    }
    return Type::makeStruct(ast->name, resolvedArgs);
  }

  if (sym->isTypeAlias && sym->aliasAST) {
    auto aliasAST = sym->aliasAST;
    std::vector<TypePtr> argTypes;
    for (size_t i = 0;
         i < aliasAST->typeParams.size() && i < ast->templateArgs.size(); ++i) {
      argTypes.push_back(resolveTypeAST(ast->templateArgs[i]));
    }
    m_symbolTable.enterScope();
    for (size_t i = 0; i < aliasAST->typeParams.size() && i < argTypes.size();
         ++i) {
      m_symbolTable.defineType(aliasAST->typeParams[i], argTypes[i]);
    }
    TypePtr resolved = resolveTypeAST(aliasAST->targetTypeAst);
    m_symbolTable.exitScope();
    if (resolved && resolved->kind != TypeKind::Error) {
      TypePtr canonicalType = resolved->underlyingType();
      if (canonicalType &&
          (canonicalType->isStruct() || canonicalType->isUnion() ||
           canonicalType->isEnum())) {
        ast->resolvedName = canonicalType->name;
      }
      auto aliasType = Type::makeAlias(sym->name, resolved);
      if (ast->isConst) aliasType->isConst = true;
      return aliasType;
    }
    return Type::makeError();
  }

  auto type = sym->type;
  if (type &&
      (type->isStruct() || type->isUnion() || type->isEnum())) {
    ast->resolvedName = type->name;
  }
  if (!ast->templateArgs.empty() && (type->isStruct() || type->isUnion())) {
    std::vector<TypePtr> resolvedArgs;
    for (const auto& argAst : ast->templateArgs) {
      resolvedArgs.push_back(resolveTypeAST(argAst));
    }
    auto instantiated = (type->isStruct())
                            ? Type::makeStruct(type->name, resolvedArgs)
                            : Type::makeUnion(type->name, resolvedArgs);
    instantiated->fields = type->fields;
    instantiated->isConst = ast->isConst;
    instantiateType(instantiated, ast->loc);
    return instantiated;
  }

  auto res = std::make_shared<Type>(*type);
  res->isConst = ast->isConst;
  return res;
}

static bool containsGenericParam(TypePtr type) {
  if (!type) return false;
  if (type->isGenericParam()) return true;
  if (type->pointerBase && containsGenericParam(type->pointerBase)) return true;
  if (type->elementType && containsGenericParam(type->elementType)) return true;
  if (type->keyType && containsGenericParam(type->keyType)) return true;
  if (type->aliasTarget && containsGenericParam(type->aliasTarget)) return true;
  for (const auto& arg : type->typeArgs) {
    if (containsGenericParam(arg)) return true;
  }
  for (const auto& param : type->paramTypes) {
    if (containsGenericParam(param)) return true;
  }
  if (type->returnType && containsGenericParam(type->returnType)) return true;
  for (const auto& elem : type->tupleElementTypes) {
    if (containsGenericParam(elem)) return true;
  }
  return false;
}

static bool isDeferredStructPointerMatch(
    TypePtr argType, TypePtr paramType,
    const std::map<std::string, TypePtr>& bindings) {
  if (!argType || !paramType || !containsGenericParam(argType)) return false;

  TypePtr effectiveArg = argType->underlyingType();
  if (effectiveArg && effectiveArg->isPointer()) {
    effectiveArg = effectiveArg->pointerBase
                       ? effectiveArg->pointerBase->underlyingType()
                       : nullptr;
  }
  TypePtr substitutedParam = paramType->substitute(bindings);
  TypePtr effectiveParam =
      substitutedParam ? substitutedParam->underlyingType() : nullptr;
  if (!effectiveArg || !effectiveParam || !effectiveArg->isStruct() ||
      !effectiveParam->isPointer() || !effectiveParam->pointerBase) {
    return false;
  }

  TypePtr paramBase = effectiveParam->pointerBase->underlyingType();
  TypePtr substitutedArg = argType->substitute(bindings);
  TypePtr resolvedArg =
      substitutedArg ? substitutedArg->underlyingType() : nullptr;
  if (resolvedArg && resolvedArg->isPointer()) {
    resolvedArg = resolvedArg->pointerBase
                      ? resolvedArg->pointerBase->underlyingType()
                      : nullptr;
  }
  return paramBase && paramBase->isStruct() && resolvedArg &&
         !containsGenericParam(resolvedArg) &&
         effectiveArg->name == paramBase->name &&
         resolvedArg->equals(paramBase);
}

static bool isDeferredGenericArgMatch(TypePtr argType, TypePtr paramType) {
  if (!argType || !paramType) return false;
  TypePtr effArg = argType->underlyingType();
  if (!effArg || !effArg->isGenericParam()) return false;
  return !containsGenericParam(paramType);
}

static IdentifierExprAST* getRootIdentifier(ExprPtr expr) {
  if (auto ident = std::dynamic_pointer_cast<IdentifierExprAST>(expr)) {
    return ident.get();
  }
  if (auto member = std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) {
    return getRootIdentifier(member->object);
  }
  if (auto unary = std::dynamic_pointer_cast<UnaryExprAST>(expr)) {
    return getRootIdentifier(unary->operand);
  }
  return nullptr;
}

static TypePtr canonicalizeTypeAliases(TypePtr type);

void TypeChecker::instantiateType(TypePtr type, const Location& loc) {
  if (!type || (!type->isStruct() && !type->isUnion()) ||
      type->typeArgs.empty())
    return;

  for (auto& arg : type->typeArgs) {
    arg = canonicalizeTypeAliases(arg);
  }

  for (const auto& arg : type->typeArgs) {
    if (containsGenericParam(arg)) return;
  }

  const std::string key = type->toString();
  const bool hasGenericDeclaration =
      type->isStruct() ? m_genericStructDecls.count(type->name) != 0
                       : m_genericUnionDecls.count(type->name) != 0;
  if (!hasGenericDeclaration) return;

  if (m_instantiatedTypeKeys.count(key)) {
    auto instantiated = m_instantiatedTypesByKey.find(key);
    if (instantiated != m_instantiatedTypesByKey.end()) {
      type->fields = instantiated->second->fields;
    }
    return;
  }
  if (m_instantiatingTypeKeys.count(key)) {
    type->fields.clear();
    return;
  }
  for (const auto& active : m_typeInstantiationStack) {
    if (active.first == type->name && active.second != key) {
      error(loc, "Unbounded recursive generic instantiation of '" +
                     type->name + "': '" + active.second + "' expands to '" +
                     key + "'");
      return;
    }
  }

  m_instantiatingTypeKeys.insert(key);
  m_typeInstantiationStack.emplace_back(type->name, key);
  struct InstantiationGuard {
    std::set<std::string>& activeKeys;
    std::vector<std::pair<std::string, std::string>>& stack;
    const std::string& key;
    ~InstantiationGuard() {
      activeKeys.erase(key);
      stack.pop_back();
    }
  } guard{m_instantiatingTypeKeys, m_typeInstantiationStack, key};

  if (type->isStruct()) {
    auto it = m_genericStructDecls.find(type->name);
    if (it != m_genericStructDecls.end()) {
      auto templateDecl = it->second;
      std::map<std::string, TypePtr> bindings;
      for (size_t i = 0;
           i < templateDecl->typeParams.size() && i < type->typeArgs.size();
           ++i) {
        bindings[templateDecl->typeParams[i]] = type->typeArgs[i];
      }

      m_symbolTable.enterScope();
      for (const auto& tp : templateDecl->typeParams) {
        auto bIt = bindings.find(tp);
        if (bIt != bindings.end() && bIt->second) {
          m_symbolTable.defineType(tp, bIt->second);
        } else {
          m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
        }
      }
      for (const auto& alias : templateDecl->typeAliases) {
        if (alias) {
          m_symbolTable.defineTypeAlias(alias->aliasName, alias);
          m_symbolTable.defineTypeAlias(key + "::" + alias->aliasName, alias);
          m_symbolTable.defineTypeAlias(templateDecl->name + "::" + alias->aliasName, alias);
        }
      }

      std::vector<Type::Field> realFields;
      for (const auto& f : templateDecl->fields) {
        TypePtr fType = resolveTypeAST(f.typeAst);
        realFields.push_back({f.name, fType});
      }
      type->fields = realFields;
      m_instantiatedTypeKeys.insert(key);
      m_instantiatedTypesByKey[key] = type;

      m_result.instantiatedTypes.push_back(type);

      std::vector<StructField> instFields;
      for (const auto& field : realFields)
        instFields.push_back(
            {field.name, makeTypeASTFromType(field.type, loc)});
      m_symbolTable.exitScope();

      auto instStruct = std::make_shared<StructDeclAST>(
          loc, key, std::vector<std::string>{}, instFields);
      instStruct->attributes = templateDecl->attributes;
      m_result.astNodesToCodeGen.push_back(instStruct);
      return;
    }
  } else if (type->isUnion()) {
    auto it = m_genericUnionDecls.find(type->name);
    if (it != m_genericUnionDecls.end()) {
      auto templateDecl = it->second;
      std::map<std::string, TypePtr> bindings;
      for (size_t i = 0;
           i < templateDecl->typeParams.size() && i < type->typeArgs.size();
           ++i) {
        bindings[templateDecl->typeParams[i]] = type->typeArgs[i];
      }

      m_symbolTable.enterScope();
      for (const auto& tp : templateDecl->typeParams) {
        auto bIt = bindings.find(tp);
        if (bIt != bindings.end() && bIt->second) {
          m_symbolTable.defineType(tp, bIt->second);
        } else {
          m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
        }
      }

      std::vector<Type::Field> realFields;
      for (const auto& f : templateDecl->fields) {
        TypePtr fType = resolveTypeAST(f.typeAst);
        realFields.push_back({f.name, fType});
      }
      type->fields = realFields;
      m_instantiatedTypeKeys.insert(key);
      m_instantiatedTypesByKey[key] = type;

      m_result.instantiatedTypes.push_back(type);

      std::vector<StructField> instFields;
      for (const auto& field : realFields)
        instFields.push_back(
            {field.name, makeTypeASTFromType(field.type, loc)});
      m_symbolTable.exitScope();

      auto instUnion = std::make_shared<UnionDeclAST>(
          loc, key, std::vector<std::string>{}, instFields);
      instUnion->attributes = templateDecl->attributes;
      m_result.astNodesToCodeGen.push_back(instUnion);
      return;
    }
  }
}

static TypePtr canonicalizeTypeAliases(TypePtr type) {
  if (!type) return nullptr;
  if (type->kind == TypeKind::Alias && type->aliasTarget) {
    TypePtr target = canonicalizeTypeAliases(type->aliasTarget);
    if (type->isConst && target) {
      target = std::make_shared<Type>(*target);
      target->isConst = true;
    }
    return target;
  }

  auto result = std::make_shared<Type>(*type);
  if (type->pointerBase) {
    result->pointerBase = canonicalizeTypeAliases(type->pointerBase);
  }
  if (type->elementType) {
    result->elementType = canonicalizeTypeAliases(type->elementType);
  }
  if (type->keyType) {
    result->keyType = canonicalizeTypeAliases(type->keyType);
  }
  if (type->returnType) {
    result->returnType = canonicalizeTypeAliases(type->returnType);
  }
  for (auto& arg : result->typeArgs) {
    arg = canonicalizeTypeAliases(arg);
  }
  for (auto& param : result->paramTypes) {
    param = canonicalizeTypeAliases(param);
  }
  for (auto& element : result->tupleElementTypes) {
    element = canonicalizeTypeAliases(element);
  }
  return result;
}

std::string TypeChecker::instantiateFunction(std::shared_ptr<FunctionDeclAST> fDecl, const std::map<std::string, TypePtr>& bindings, const Location& loc) {
  if (!fDecl) return "";

  if (fDecl->typeParams.empty()) {
    return fDecl->mangledName.empty() ? fDecl->name : fDecl->mangledName;
  }

  for (const auto& tp : fDecl->typeParams) {
    auto it = bindings.find(tp);
    if (it == bindings.end() || !it->second || containsGenericParam(it->second)) {
      return "";
    }
  }

  m_symbolTable.enterScope();
  for (const auto& tp : fDecl->typeParams) {
    auto bIt = bindings.find(tp);
    if (bIt != bindings.end()) {
      m_symbolTable.defineType(tp, bIt->second);
    } else {
      m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
    }
  }

  std::vector<ParamDecl> instParams;
  std::vector<TypePtr> pTypes;
  for (const auto& p : fDecl->parameters) {
    TypePtr pType = resolveTypeAST(p.typeAst);
    if (p.isVariadic) pType = normalizeVariadicParameterType(pType);
    TypePtr subPType = pType ? pType->substitute(bindings) : nullptr;
    pTypes.push_back(subPType);
    instParams.push_back(
        {p.name, makeTypeASTFromType(subPType, loc), p.isVariadic});
  }

  const std::string scopedOwner = fDecl->ownerTypeName;
  std::string mangledOwner = scopedOwner;
  if (!scopedOwner.empty()) {
    auto sym = m_symbolTable.lookupType(scopedOwner);
    if (sym && sym->type) {
      std::vector<TypePtr> tArgs;
      for (const auto& tp : fDecl->typeParams) {
        auto bIt = bindings.find(tp);
        if (bIt != bindings.end()) tArgs.push_back(bIt->second);
      }
      if (!tArgs.empty()) {
        auto instType = Type::makeStruct(scopedOwner, tArgs);
        mangledOwner = instType->toString();
      }
    }
  }

  std::string instMangled =
      mangleFunctionName(fDecl->name, mangledOwner, pTypes);
  if (!fDecl->typeParams.empty()) {
    instMangled += "_G";
    for (const auto& tp : fDecl->typeParams) {
      auto binding = bindings.find(tp);
      if (binding != bindings.end()) {
        instMangled += mangleType(binding->second);
      }
    }
  }
  instMangled = qualifyImportedFunctionName(*fDecl, instMangled);

  if (m_instantiatedFuncKeys.find(instMangled) !=
      m_instantiatedFuncKeys.end()) {
    m_symbolTable.exitScope();
    return instMangled;
  }
  m_instantiatedFuncKeys.insert(instMangled);

  TypePtr retType = resolveTypeAST(fDecl->returnTypeAst);
  TypePtr subRetType =
      retType ? retType->substitute(bindings) : Type::makePrimitive("void");
  TypeASTPtr instRetAst = makeTypeASTFromType(subRetType, loc);
  ExprPtr instBody = cloneExpr(fDecl->body);
  substituteGenericExpressionTypes(instBody, bindings);

  auto instFunc = std::make_shared<FunctionDeclAST>(
      loc, fDecl->name, scopedOwner,
      std::vector<std::string>{},  // empty typeParams -> concrete
      instParams, instRetAst, instBody, fDecl->isShorthand);
  instFunc->attributes = fDecl->attributes;

  instFunc->inferredType = Type::makeFunction(pTypes, subRetType);
  instFunc->mangledName = instMangled;
  m_symbolTable.defineFunction(instFunc->name, instFunc->ownerTypeName,
                               instFunc->inferredType, instFunc, instMangled);

  checkDeclaration(instFunc);

  m_symbolTable.exitScope();

  m_result.instantiatedFunctions.push_back(instFunc);
  m_result.astNodesToCodeGen.push_back(instFunc);

  return instMangled;
}

void TypeChecker::substituteGenericExpressionTypes(
    ExprPtr expr, const std::map<std::string, TypePtr>& bindings) {
  std::function<void(ExprPtr)> visitExpression;
  std::function<void(StmtPtr)> visitStatement;

  auto substituteAnnotation = [&](TypeASTPtr& annotation) {
    if (!annotation) return;
    TypePtr resolved = resolveTypeAST(annotation);
    if (resolved && resolved->kind != TypeKind::Error) {
      resolved = resolved->substitute(bindings);
      annotation = makeTypeASTFromType(resolved, annotation->loc);
    }
  };

  visitStatement = [&](StmtPtr stmt) {
    if (!stmt) return;
    if (stmt->inferredType) {
      stmt->inferredType = stmt->inferredType->substitute(bindings);
    }
    if (auto variable = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
      substituteAnnotation(variable->typeAst);
      visitExpression(variable->initializer);
    } else if (auto binding =
                   std::dynamic_pointer_cast<StructuralBindingStmtAST>(stmt)) {
      substituteAnnotation(binding->typeAst);
      visitExpression(binding->initializer);
    } else if (auto expression =
                   std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
      visitExpression(expression->expr);
    } else if (auto returned =
                   std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
      visitExpression(returned->value);
    } else if (auto yielded =
                   std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
      visitExpression(yielded->value);
    } else if (auto deferred =
                   std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
      visitStatement(deferred->deferredStmt);
    } else if (auto loop = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
      visitExpression(loop->condition);
      visitStatement(loop->body);
    } else if (auto loop = std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
      visitStatement(loop->body);
      visitExpression(loop->condition);
    } else if (auto loop = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
      visitStatement(loop->init);
      visitExpression(loop->condition);
      visitExpression(loop->post);
      visitStatement(loop->body);
    }
  };

  visitExpression = [&](ExprPtr current) {
    if (!current) return;
    if (current->inferredType) {
      current->inferredType = current->inferredType->substitute(bindings);
    }
    if (auto node = std::dynamic_pointer_cast<TupleLiteralExprAST>(current)) {
      for (const auto& element : node->elements) visitExpression(element);
    } else if (auto node =
                   std::dynamic_pointer_cast<ArrayLiteralExprAST>(current)) {
      for (const auto& element : node->elements) visitExpression(element);
    } else if (auto node =
                   std::dynamic_pointer_cast<MapLiteralExprAST>(current)) {
      for (const auto& entry : node->entries) {
        visitExpression(entry.first);
        visitExpression(entry.second);
      }
    } else if (auto node = std::dynamic_pointer_cast<IndexExprAST>(current)) {
      visitExpression(node->target);
      visitExpression(node->index);
    } else if (auto node = std::dynamic_pointer_cast<SliceExprAST>(current)) {
      visitExpression(node->target);
      visitExpression(node->startExpr);
      visitExpression(node->endExpr);
    } else if (auto node = std::dynamic_pointer_cast<BinaryExprAST>(current)) {
      visitExpression(node->left);
      visitExpression(node->right);
    } else if (auto node = std::dynamic_pointer_cast<UnaryExprAST>(current)) {
      visitExpression(node->operand);
    } else if (auto node =
                   std::dynamic_pointer_cast<PostfixUnaryExprAST>(current)) {
      visitExpression(node->operand);
    } else if (auto node =
                   std::dynamic_pointer_cast<MemberAccessExprAST>(current)) {
      visitExpression(node->object);
    } else if (auto node = std::dynamic_pointer_cast<CallExprAST>(current)) {
      for (auto& typeArg : node->templateArgs) {
        substituteAnnotation(typeArg);
      }
      for (auto& paramType : node->targetParamTypes) {
        if (paramType) paramType = paramType->substitute(bindings);
      }
      if (node->targetReturnType) {
        node->targetReturnType =
            node->targetReturnType->substitute(bindings);
      }
      visitExpression(node->callee);
      for (const auto& argument : node->arguments)
        visitExpression(argument);
    } else if (auto node =
                   std::dynamic_pointer_cast<StaticMethodCallExprAST>(current)) {
      for (auto& typeArg : node->templateArgs) {
        substituteAnnotation(typeArg);
      }
      for (auto& paramType : node->targetParamTypes) {
        if (paramType) paramType = paramType->substitute(bindings);
      }
      if (node->targetReturnType) {
        node->targetReturnType =
            node->targetReturnType->substitute(bindings);
      }
      for (const auto& argument : node->arguments)
        visitExpression(argument);
    } else if (auto node =
                   std::dynamic_pointer_cast<StructInitExprAST>(current)) {
      substituteAnnotation(node->structType);
      for (const auto& field : node->fieldInits)
        visitExpression(field.second);
    } else if (auto node = std::dynamic_pointer_cast<YieldExprAST>(current)) {
      visitExpression(node->yieldedExpr);
    } else if (auto node = std::dynamic_pointer_cast<BlockExprAST>(current)) {
      for (const auto& statement : node->statements)
        visitStatement(statement);
      visitExpression(node->yieldExpr);
    } else if (auto node = std::dynamic_pointer_cast<IfExprAST>(current)) {
      visitExpression(node->condition);
      visitExpression(node->thenBranch);
      visitExpression(node->elseBranch);
    } else if (auto node = std::dynamic_pointer_cast<SwitchExprAST>(current)) {
      visitExpression(node->targetExpr);
      for (const auto& item : node->cases) {
        visitExpression(item.pattern);
        visitExpression(item.rangeEnd);
        visitExpression(item.body);
      }
    } else if (auto node =
                   std::dynamic_pointer_cast<ClosureExprAST>(current)) {
      for (auto& param : node->params)
        substituteAnnotation(param.typeAst);
      substituteAnnotation(node->returnTypeAst);
      visitExpression(node->body);
    } else if (auto node = std::dynamic_pointer_cast<AssignExprAST>(current)) {
      visitExpression(node->target);
      visitExpression(node->value);
    } else if (auto node = std::dynamic_pointer_cast<CastExprAST>(current)) {
      substituteAnnotation(node->targetTypeAst);
      visitExpression(node->expr);
    }
  };

  visitExpression(expr);
}

void TypeChecker::registerTypes(std::shared_ptr<ProgramAST> program) {
  for (const auto& decl : program->declarations) {
    if (auto sDecl = std::dynamic_pointer_cast<StructDeclAST>(decl)) {
      m_allStructDecls[sDecl->name] = sDecl;
      std::vector<TypePtr> typeParams;
      for (const auto& tp : sDecl->typeParams) {
        typeParams.push_back(Type::makeGenericParam(tp));
      }
      auto stType = Type::makeStruct(sDecl->name, typeParams);
      m_symbolTable.defineType(sDecl->name, stType);
      if (!sDecl->typeParams.empty()) {
        m_genericStructDecls[sDecl->name] = sDecl;
      }
      for (const auto& alias : sDecl->typeAliases) {
        if (alias) {
          m_symbolTable.defineTypeAlias(sDecl->name + "::" + alias->aliasName, alias);
        }
      }
    } else if (auto uDecl = std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
      std::vector<TypePtr> typeParams;
      for (const auto& tp : uDecl->typeParams) {
        typeParams.push_back(Type::makeGenericParam(tp));
      }
      auto unType = Type::makeUnion(uDecl->name, typeParams);
      m_symbolTable.defineType(uDecl->name, unType);
      if (!uDecl->typeParams.empty()) {
        m_genericUnionDecls[uDecl->name] = uDecl;
      }
    } else if (auto eDecl = std::dynamic_pointer_cast<EnumDeclAST>(decl)) {
      auto enType = Type::makeEnum(eDecl->name, eDecl->enumerators);
      m_symbolTable.defineType(eDecl->name, enType);
      for (const auto& item : eDecl->enumerators) {
        m_symbolTable.defineVar(eDecl->name + "::" + item, enType, true);
        if (!m_symbolTable.lookupVar(item)) {
          m_symbolTable.defineVar(item, enType, true);
        }
      }
    } else if (auto tAlias =
                   std::dynamic_pointer_cast<TypeAliasDeclAST>(decl)) {
      m_symbolTable.defineTypeAlias(tAlias->aliasName, tAlias);
    }
  }

  // Fill struct / union fields after registering names
  for (const auto& decl : program->declarations) {
    if (auto sDecl = std::dynamic_pointer_cast<StructDeclAST>(decl)) {
      Symbol* sym = m_symbolTable.lookupType(sDecl->name);
      if (sym && sym->type) {
        m_symbolTable.enterScope();
        for (const auto& tp : sDecl->typeParams) {
          m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
        }
        for (const auto& alias : sDecl->typeAliases) {
          if (alias) {
            m_symbolTable.defineTypeAlias(alias->aliasName, alias);
          }
        }
        sym->type->fields.clear();
        for (auto& f : sDecl->fields) {
          TypePtr fType = resolveTypeAST(f.typeAst);
          sym->type->fields.push_back({f.name, fType});
          if (sDecl->typeParams.empty() && fType &&
              fType->kind != TypeKind::Error &&
              (!f.typeAst || !f.typeAst->isRuntimeSizedArray)) {
            f.typeAst = makeTypeASTFromType(
                fType, f.typeAst ? f.typeAst->loc : sDecl->loc);
          }
        }
        m_symbolTable.exitScope();
      }
    } else if (auto uDecl = std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
      Symbol* sym = m_symbolTable.lookupType(uDecl->name);
      if (sym && sym->type) {
        m_symbolTable.enterScope();
        for (const auto& tp : uDecl->typeParams) {
          m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
        }
        sym->type->fields.clear();
        for (auto& f : uDecl->fields) {
          TypePtr fType = resolveTypeAST(f.typeAst);
          sym->type->fields.push_back({f.name, fType});
          if (uDecl->typeParams.empty() && fType &&
              fType->kind != TypeKind::Error &&
              (!f.typeAst || !f.typeAst->isRuntimeSizedArray)) {
            f.typeAst = makeTypeASTFromType(
                fType, f.typeAst ? f.typeAst->loc : uDecl->loc);
          }
        }
        m_symbolTable.exitScope();
      }
    }
  }
}

void TypeChecker::registerFunctions(std::shared_ptr<ProgramAST> program) {
  auto looksLikeImplicitTypeParam = [](const std::string& name) {
    return name.size() == 1 && name[0] >= 'A' && name[0] <= 'Z';
  };
  for (const auto& decl : program->declarations) {
    if (auto fDecl = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
      if (fDecl->typeParams.empty()) {
        // Implicit generic parameters: a bare single-letter type name that is
        // not a known type (for example `T` in `List<T> f(List<T> x)`) is
        // treated as a type parameter. This keeps generic declarations that
        // omit the explicit `<T>` list working without inventing a struct.
        std::vector<std::string> implicitParams;
        std::function<void(TypeASTPtr)> collect = [&](TypeASTPtr typeAst) {
          if (!typeAst) return;
          const std::string& typeName = typeAst->name;
          if (looksLikeImplicitTypeParam(typeName) &&
              !m_symbolTable.lookupType(typeName) &&
              std::find(implicitParams.begin(), implicitParams.end(),
                        typeName) == implicitParams.end()) {
            implicitParams.push_back(typeName);
          }
          collect(typeAst->pointerBase);
          collect(typeAst->elementType);
          collect(typeAst->keyType);
          collect(typeAst->returnType);
          for (const auto& arg : typeAst->templateArgs) collect(arg);
          for (const auto& elem : typeAst->tupleElementTypes) collect(elem);
          for (const auto& param : typeAst->paramTypes) collect(param);
        };
        collect(fDecl->returnTypeAst);
        for (const auto& p : fDecl->parameters) collect(p.typeAst);
        if (!implicitParams.empty()) {
          fDecl->typeParams = std::move(implicitParams);
        }
      }

      m_symbolTable.enterScope();
      for (const auto& tp : fDecl->typeParams) {
        m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
      }
      std::vector<TypePtr> pTypes;
      for (const auto& p : fDecl->parameters) {
        TypePtr pType = resolveTypeAST(p.typeAst);
        if (p.isVariadic) pType = normalizeVariadicParameterType(pType);
        pTypes.push_back(pType);
      }
      TypePtr retType = resolveTypeAST(fDecl->returnTypeAst);
      m_symbolTable.exitScope();

      auto funcType = Type::makeFunction(pTypes, retType);

      bool isCurrentExtern =
          hasAttribute(fDecl->attributes, "extern") || (fDecl->body == nullptr);

      std::vector<Symbol*> existing =
          fDecl->ownerTypeName.empty()
              ? m_symbolTable.lookupFunctions(fDecl->name)
              : m_symbolTable.lookupStaticMethods(fDecl->ownerTypeName,
                                                  fDecl->name);

      if (!existing.empty()) {
        bool hasExtern = isCurrentExtern;
        for (Symbol* sym : existing) {
          if (sym->funcAST &&
              (hasAttribute(sym->funcAST->attributes, "extern") ||
               sym->funcAST->body == nullptr)) {
            hasExtern = true;
            break;
          }
        }

        if (hasExtern) {
          error(fDecl->loc,
                "Cannot overload extern function '" +
                    (fDecl->ownerTypeName.empty()
                         ? fDecl->name
                         : fDecl->ownerTypeName + "::" + fDecl->name) +
                    "'");
          continue;
        }

        bool redefinition = false;
        for (Symbol* sym : existing) {
          if (sym->type && sym->type->isFunction() &&
              sym->type->paramTypes.size() == pTypes.size()) {
            bool exactParams = true;
            for (size_t i = 0; i < pTypes.size(); ++i) {
              if (!pTypes[i] || !sym->type->paramTypes[i] ||
                  !pTypes[i]->equals(sym->type->paramTypes[i])) {
                exactParams = false;
                break;
              }
            }
            if (exactParams) {
              redefinition = true;
              break;
            }
          }
        }

        if (redefinition) {
          error(fDecl->loc,
                "Redefinition of function '" +
                    (fDecl->ownerTypeName.empty()
                         ? fDecl->name
                         : fDecl->ownerTypeName + "::" + fDecl->name) +
                    "' with identical parameter types");
          continue;
        }
      }

      std::string extLinkName = getExternLinkName(fDecl->attributes);
      std::string mangled;
      if (fDecl->name == "main") {
        mangled = "main";
      } else if (isCurrentExtern) {
        mangled = extLinkName.empty() ? fDecl->name : extLinkName;
      } else {
        mangled = mangleFunctionName(fDecl->name, fDecl->ownerTypeName, pTypes);
      }
      if (!isCurrentExtern) {
        mangled = qualifyImportedFunctionName(*fDecl, mangled);
      }
      fDecl->mangledName = mangled;

      m_symbolTable.defineFunction(fDecl->name, fDecl->ownerTypeName, funcType,
                                   fDecl, mangled);

      if (!fDecl->typeParams.empty()) {
        m_genericFuncDecls[fDecl->ownerTypeName.empty()
                               ? fDecl->name
                               : (fDecl->ownerTypeName + "::" + fDecl->name)] =
            fDecl;
      }
    }
  }
}

void TypeChecker::registerTopLevelVariables(std::shared_ptr<ProgramAST> program) {
  if (!program) return;
  for (const auto& stmt : program->topStatements) {
    if (auto vStmt = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
      if (vStmt->typeAst) {
        TypePtr declType = resolveTypeAST(vStmt->typeAst);
        if (declType) {
          vStmt->inferredType = declType;
          m_symbolTable.defineVar(vStmt->name, declType, vStmt->isConst,
                                  vStmt->isStatic);
        }
      }
    }
  }
  for (const auto& stmt : program->topStatements) {
    if (auto vStmt = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
      TypePtr declType =
          vStmt->inferredType
              ? vStmt->inferredType
              : (vStmt->typeAst ? resolveTypeAST(vStmt->typeAst) : nullptr);
      if (vStmt->initializer) {
        TypePtr expectedInitType =
            declType && declType->name != "auto" ? declType : nullptr;
        TypePtr initType = checkExpression(vStmt->initializer,
                                           expectedInitType);
        if (!declType || declType->name == "auto") {
          declType = initType;
        }
      }
      if (!declType) declType = Type::makePrimitive("int");
      vStmt->inferredType = declType;
      m_symbolTable.defineVar(vStmt->name, declType, vStmt->isConst,
                              vStmt->isStatic);
    }
  }
}

void TypeChecker::processImports(std::shared_ptr<ProgramAST> program) {
  if (!program) return;

  for (const auto& importStmt : program->imports) {
    for (const auto& item : importStmt.items) {
      std::string modPath = item.modulePath;

      if (m_activeImports.count(modPath) > 0) {
        std::string cycleStr;
        for (const auto& active : m_importStack) {
          cycleStr += active + " -> ";
        }
        cycleStr += modPath;
        error(importStmt.loc, "Circular import detected: " + cycleStr);
        continue;
      }

      if (m_importedModules.count(modPath) == 0) {
        std::string sourceCode;
        auto it = m_virtualModuleSources.find(modPath);
        if (it != m_virtualModuleSources.end()) {
          sourceCode = it->second;
        } else {
          std::string relativePath = modPath;
          for (char& c : relativePath) {
            if (c == '.') c = '/';
          }
          relativePath += ".g";

          std::vector<std::string> searchPaths = {
              relativePath,
              "std/" + relativePath,
              "../" + relativePath,
              "../std/" + relativePath,
              "examples/" + relativePath,
              "../examples/" + relativePath,
              "/app/applet/cpp/" + relativePath,
              "/app/applet/cpp/std/" + relativePath,
              "/app/applet/cpp/examples/" + relativePath};

          bool loaded = false;
          for (const auto& sp : searchPaths) {
            std::ifstream f(sp);
            if (f.is_open()) {
              sourceCode = std::string((std::istreambuf_iterator<char>(f)),
                                       std::istreambuf_iterator<char>());
              loaded = true;
              break;
            }
          }

          if (!loaded) {
            error(importStmt.loc, "Module not found: '" + modPath + "'");
            continue;
          }
        }

        Lexer modLexer(modPath, sourceCode);
        auto modTokens = modLexer.tokenize();
        Parser modParser(modTokens);
        auto modProgram = modParser.parseProgram();

        if (modLexer.hasErrors()) {
          for (const Error& err : modLexer.errors()) {
            error(importStmt.loc,
                  "Syntax error while importing '" + modPath + "'");

            auto loc = Location{err.filename, err.line, err.column};
            error(loc,err.message,
                  err.token);
          }
          continue;
        }

        if (modParser.hasErrors()) {
          for (const Error& err : modParser.errors()) {
            error(importStmt.loc,
                  "Syntax error while importing '" + modPath + "'");

            auto loc = Location{err.filename, err.line, err.column};
            error(loc,err.message,
                  err.token);
          }
          continue;
        }

        m_activeImports.insert(modPath);
        m_importStack.push_back(modPath);

        // Recursively process imports of imported module
        processImports(modProgram);

        // Register types and functions from imported module into symbol table
        registerTypes(modProgram);
        registerFunctions(modProgram);
        registerTopLevelVariables(modProgram);
        for (const auto& decl : modProgram->declarations) {
          bool emitImportedDecl = false;
          if (auto structDecl =
                  std::dynamic_pointer_cast<StructDeclAST>(decl)) {
            emitImportedDecl =
                structDecl->typeParams.empty() ||
                hasAttribute(structDecl->attributes, "core");
          } else if (auto unionDecl =
                         std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
            emitImportedDecl = unionDecl->typeParams.empty();
          } else if (auto enumDecl =
                         std::dynamic_pointer_cast<EnumDeclAST>(decl)) {
            emitImportedDecl = true;
          } else if (auto functionDecl =
                         std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
            emitImportedDecl = functionDecl->name != "main" &&
                               functionDecl->typeParams.empty();
          }
          checkDeclaration(decl);
          if (emitImportedDecl &&
              std::find(m_result.astNodesToCodeGen.begin(),
                        m_result.astNodesToCodeGen.end(), decl) ==
                  m_result.astNodesToCodeGen.end()) {
            m_result.astNodesToCodeGen.push_back(decl);
          }
        }
        for (const auto& stmt : modProgram->topStatements) {
          if (std::dynamic_pointer_cast<VarDeclStmtAST>(stmt) &&
              std::find(m_result.astNodesToCodeGen.begin(),
                        m_result.astNodesToCodeGen.end(), stmt) ==
                  m_result.astNodesToCodeGen.end()) {
            m_result.astNodesToCodeGen.push_back(stmt);
          }
        }

        m_importStack.pop_back();
        m_activeImports.erase(modPath);
        m_importedModules.insert(modPath);
      }

      // Selective import check
      if (!item.selectiveSymbols.empty()) {
        for (const auto& symName : item.selectiveSymbols) {
          Symbol* symVar = m_symbolTable.lookupVar(symName);
          Symbol* symType = m_symbolTable.lookupType(symName);
          if (!symType) {
            const size_t moduleNameEnd = modPath.rfind('.');
            if (moduleNameEnd != std::string::npos) {
              std::string moduleNamespace = modPath.substr(0, moduleNameEnd);
              size_t namespacePos = 0;
              while ((namespacePos = moduleNamespace.find(
                          '.', namespacePos)) != std::string::npos) {
                moduleNamespace.replace(namespacePos, 1, "::");
                namespacePos += 2;
              }
              Symbol* qualifiedType = m_symbolTable.lookupType(
                  moduleNamespace + "::" + symName);
              if (qualifiedType && qualifiedType->isType) {
                if (qualifiedType->isTypeAlias && qualifiedType->aliasAST) {
                  m_symbolTable.defineTypeAlias(symName,
                                                qualifiedType->aliasAST);
                } else if (qualifiedType->type) {
                  m_symbolTable.defineType(symName, qualifiedType->type);
                }
                symType = m_symbolTable.lookupType(symName);
              }
            }
          }
          auto symFuncs = m_symbolTable.lookupFunctions(symName);
          if (!symVar && !symType && symFuncs.empty()) {
            error(importStmt.loc, "Selective import error: Symbol '" + symName +
                                      "' not found in module '" + modPath +
                                      "'");
          }
        }
      }
    }
  }
}

TypeCheckResult TypeChecker::check(std::shared_ptr<ProgramAST> program) {
  m_result = TypeCheckResult();
  m_disallowCustomOperators = false;
  m_instantiatedTypeKeys.clear();
  m_instantiatingTypeKeys.clear();
  m_instantiatedTypesByKey.clear();
  m_instantiatedFuncKeys.clear();
  m_activeImports.clear();
  m_importStack.clear();
  m_importedModules.clear();

  if (!program) return m_result;

  processImports(program);

  registerTypes(program);
  registerFunctions(program);
  registerTopLevelVariables(program);

  for (const auto& stmt : program->topStatements) {
    checkStatement(stmt);
    m_result.astNodesToCodeGen.push_back(stmt);
  }

  for (const auto& decl : program->declarations) {
    checkDeclaration(decl);

    if (auto fDecl = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
      if (fDecl->typeParams.empty()) {
        m_result.astNodesToCodeGen.push_back(fDecl);
      }
    } else if (auto sDecl = std::dynamic_pointer_cast<StructDeclAST>(decl)) {
      if (sDecl->typeParams.empty()) {
        m_result.astNodesToCodeGen.push_back(sDecl);
      } else if (hasAttribute(sDecl->attributes, "core")) {
        m_result.astNodesToCodeGen.push_back(sDecl);
      }
    } else if (auto uDecl = std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
      if (uDecl->typeParams.empty()) {
        m_result.astNodesToCodeGen.push_back(uDecl);
      }
    } else if (auto eDecl = std::dynamic_pointer_cast<EnumDeclAST>(decl)) {
      m_result.astNodesToCodeGen.push_back(eDecl);
    }
  }

  std::vector<DeclPtr> concreteDecls;
  for (const auto& node : m_result.astNodesToCodeGen) {
    if (auto d = std::dynamic_pointer_cast<DeclAST>(node)) {
      if (std::find(concreteDecls.begin(), concreteDecls.end(), d) ==
          concreteDecls.end()) {
        concreteDecls.push_back(d);
      }
    }
  }
  program->declarations = std::move(concreteDecls);

  return m_result;
}

static bool isIntegerType(TypePtr t) {
  if (!t) return false;
  t = t->underlyingType();
  if (!t || !t->isPrimitive()) return false;
  const std::string& n = t->name;
  return n == "int" || n == "uint" || n == "short" || n == "ushort" ||
         n == "long" || n == "ulong" || n == "size_t" || n == "char" ||
         n == "uchar" || n == "bool";
}

static bool isFloatType(TypePtr t) {
  if (!t) return false;
  t = t->underlyingType();
  if (!t || !t->isPrimitive()) return false;
  const std::string& n = t->name;
  return n == "float" || n == "double";
}

static bool isVoidPointerType(TypePtr t) {
  if (!t) return false;
  t = t->underlyingType();
  return t && t->isPointer() && t->pointerBase && t->pointerBase->isVoid();
}

static bool isAssignable(TypePtr src, TypePtr target) {
  if (!src || !target) return true;
  if (src->kind == TypeKind::Error || target->kind == TypeKind::Error)
    return true;
  if (target->kind == TypeKind::Unknown || src->kind == TypeKind::Unknown)
    return true;

  // Unwrap alias types for assignability checks so aliases behave like their
  // targets.
  // This keeps type aliases comparable by their underlying base type while
  // preserving the alias spelling in source code and diagnostics.
  TypePtr effSrc = src ? src->underlyingType() : nullptr;
  TypePtr effTarget = target ? target->underlyingType() : nullptr;
  if (!effSrc) effSrc = src;
  if (!effTarget) effTarget = target;

  if (effTarget->equals(effSrc)) return true;

  if (isVoidPointerType(effTarget)) {
    return true;
  }

  // For function pointer comparisons, consider pointer base if pointing to
  // function/closure
  if (effTarget->isPointer() && effTarget->pointerBase &&
      (effTarget->pointerBase->isFunction() ||
       effTarget->pointerBase->isClosure())) {
    TypePtr unwrapped = effTarget->pointerBase->underlyingType();
    if (unwrapped) effTarget = unwrapped;
  }
  if (effSrc->isPointer() && effSrc->pointerBase &&
      (effSrc->pointerBase->isFunction() || effSrc->pointerBase->isClosure())) {
    TypePtr unwrapped = effSrc->pointerBase->underlyingType();
    if (unwrapped) effSrc = unwrapped;
  }

  if ((effTarget->isFunction() || effTarget->isClosure()) &&
      (effSrc->isFunction() || effSrc->isClosure())) {
    if (effTarget->paramTypes.size() != effSrc->paramTypes.size()) {
      return false;
    }
    for (size_t i = 0; i < effTarget->paramTypes.size(); ++i) {
      if (!isAssignable(effSrc->paramTypes[i], effTarget->paramTypes[i]) &&
          !isAssignable(effTarget->paramTypes[i], effSrc->paramTypes[i])) {
        return false;
      }
    }
    if (effTarget->returnType && effSrc->returnType) {
      if (!isAssignable(effSrc->returnType, effTarget->returnType)) {
        return false;
      }
    }
    return true;
  }

  if (effTarget->isTuple() && effSrc->isTuple()) {
    if (effTarget->tupleElementTypes.size() != effSrc->tupleElementTypes.size()) {
      return false;
    }
    for (size_t i = 0; i < effTarget->tupleElementTypes.size(); ++i) {
      if (!isAssignable(effSrc->tupleElementTypes[i],
                        effTarget->tupleElementTypes[i])) {
        return false;
      }
    }
    return true;
  }

  if (effTarget->isPointer() && effSrc->isPointer()) {
    return true;
  }

  // C-style array decay: a fixed array or slice can be passed where a pointer
  // to its element type is expected.
  if (effTarget->isPointer() &&
      (effSrc->isArray() || effSrc->isSlice())) {
    return true;
  }

  if ((effTarget->isStruct() || effTarget->isUnion()) &&
      (effSrc->isStruct() || effSrc->isUnion())) {
    if (effTarget->name == effSrc->name &&
        effTarget->typeArgs.size() == effSrc->typeArgs.size()) {
      bool allOk = true;
      for (size_t i = 0; i < effTarget->typeArgs.size(); ++i) {
        if (!isAssignable(effSrc->typeArgs[i], effTarget->typeArgs[i])) {
          allOk = false;
          break;
        }
      }
      if (allOk) return true;
    }
  }

  if ((effTarget->isArray() || effTarget->isSlice()) &&
      (effSrc->isArray() || effSrc->isSlice())) {
    if (effTarget->elementType && effSrc->elementType) {
      return isAssignable(effSrc->elementType, effTarget->elementType);
    }
    return true;
  }

  if (effTarget->isHashMap() && effSrc->isHashMap()) {
    if (effTarget->keyType && effSrc->keyType && effTarget->elementType &&
        effSrc->elementType) {
      return isAssignable(effSrc->keyType, effTarget->keyType) &&
             isAssignable(effSrc->elementType, effTarget->elementType);
    }
    return true;
  }

  if (effTarget->isHashMap()) {
      return isAssignable(effSrc, effTarget->elementType);
  }

  if (isFloatType(effTarget) && isIntegerType(effSrc)) {
    return true;
  }

  if (isFloatType(effTarget) && isFloatType(effSrc)) {
    return true;
  }

  if (isIntegerType(effTarget) && isIntegerType(effSrc)) {
    return true;
  }

  if (effTarget->isGenericParam() || effSrc->isGenericParam()) {
    return true;
  }

  return false;
}

static bool isVariadicArgAssignable(TypePtr src, TypePtr target) {
  if (!src || !target) return true;
  if (src->kind == TypeKind::Error || target->kind == TypeKind::Error)
    return true;
  if (target->kind == TypeKind::Unknown || src->kind == TypeKind::Unknown)
    return true;

  TypePtr effTarget = target->underlyingType();
  if (effTarget && effTarget->isPointer() && effTarget->pointerBase &&
      effTarget->pointerBase->isVoid()) {
    return true;
  }

  if ((target->isArray() || target->isSlice()) &&
      (src->isArray() || src->isSlice())) {
    if (target->elementType && src->elementType) {
      return isVariadicArgAssignable(src->elementType, target->elementType);
    }
  }
  return isAssignable(src, target);
}

static std::string baseTypeName(const std::string& typeName) {
  size_t anglePos = typeName.find('<');
  return anglePos == std::string::npos ? typeName
                                       : typeName.substr(0, anglePos);
}

void TypeChecker::checkDeclaration(DeclPtr decl) {
  if (auto fDecl = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
    const bool isInfix = hasAttribute(fDecl->attributes, "infix_operator");
    const bool isPrefix = hasAttribute(fDecl->attributes, "prefix_operator");
    const bool isPostfix = hasAttribute(fDecl->attributes, "postfix_operator");
    const int operatorKinds =
        static_cast<int>(isInfix) + static_cast<int>(isPrefix) +
        static_cast<int>(isPostfix);
    if (operatorKinds > 1) {
      error(fDecl->loc,
            "Operator '" + fDecl->name +
                "' cannot be declared as more than one operator kind");
    } else if (operatorKinds == 1) {
      const size_t expectedParams = isInfix ? 2 : 1;
      if (fDecl->parameters.size() != expectedParams) {
        error(fDecl->loc,
              std::string(isInfix ? "Infix" : (isPrefix ? "Prefix" : "Postfix")) +
                  " operator '" + fDecl->name + "' must take exactly " +
                  std::to_string(expectedParams) +
                  (expectedParams == 1 ? " parameter" : " parameters"));
      }
    }

    if (!fDecl->ownerTypeName.empty()) {
      Symbol* ownerSym =
          m_symbolTable.lookupType(baseTypeName(fDecl->ownerTypeName));
      if (!ownerSym || !ownerSym->isType) {
        error(fDecl->loc, "Scoped function '" + fDecl->name +
                              "' refers to unknown type '" +
                              fDecl->ownerTypeName + "'");
      }
    }

    if (!fDecl->typeParams.empty()) {
      // Uninstantiated generic function template; body will be type checked
      // when instantiated
      return;
    }

    m_symbolTable.enterScope();

    // Check attributes on function declaration
    for (const auto& attr : fDecl->attributes) {
      for (const auto& arg : attr.args) {
        if (arg.value) {
          checkExpression(arg.value);
        }
      }
    }

    if (hasAttribute(fDecl->attributes, "user_literal")) {
      if (fDecl->parameters.size() != 1) {
        error(fDecl->loc, "User defined literal function '" + fDecl->name +
                              "' must take exactly 1 parameter");
      }
    }

    // Register and verify parameters
    std::vector<TypePtr> pTypes;
    for (const auto& p : fDecl->parameters) {
      TypePtr pType = resolveTypeAST(p.typeAst);
      if (p.isVariadic) pType = normalizeVariadicParameterType(pType);
      pTypes.push_back(pType);
      m_symbolTable.defineVar(p.name, pType, false);
    }

    if (fDecl->mangledName.empty()) {
      fDecl->mangledName =
          mangleFunctionName(fDecl->name, fDecl->ownerTypeName, pTypes);
    }

    TypePtr expectedRet = resolveTypeAST(fDecl->returnTypeAst);
    fDecl->returnTypeAst = makeTypeASTFromType(expectedRet, fDecl->loc);
    for (size_t i = 0; i < fDecl->parameters.size(); ++i) {
      fDecl->parameters[i].typeAst = makeTypeASTFromType(pTypes[i], fDecl->loc);
    }

    TypePtr oldRet = m_currentReturnType;
    bool oldHasReturn = m_hasReturnStmt;
    bool oldDisallowCustomOperators = m_disallowCustomOperators;
    m_currentReturnType = expectedRet;
    m_hasReturnStmt = false;
    m_disallowCustomOperators =
        oldDisallowCustomOperators ||
        hasAttribute(fDecl->attributes, "no_custom_operators");

    if (fDecl->body) {
      TypePtr bodyType;
      if (auto arrLit =
              std::dynamic_pointer_cast<ArrayLiteralExprAST>(fDecl->body)) {
        bodyType = checkArrayLiteralExpr(arrLit, expectedRet);
      } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(
                     fDecl->body)) {
        bodyType = checkMapLiteralExpr(mapLit, expectedRet);
      } else {
        bodyType = checkExpression(fDecl->body, expectedRet);
      }
      fDecl->inferredType = Type::makeFunction(pTypes, expectedRet ? expectedRet : bodyType);

      if (fDecl->isShorthand) {
        if (expectedRet && !expectedRet->isGenericParam() &&
            !bodyType->equals(expectedRet)) {
          // Check if shorthand body type matches expected
          if (expectedRet->name != "void" &&
              bodyType->kind != TypeKind::Error) {
            if (!isAssignable(bodyType, expectedRet)) {
              error(fDecl->loc, "Return type mismatch in function '" +
                                    fDecl->name + "': cannot convert '" +
                                    bodyType->toString() + "' to '" +
                                    expectedRet->toString() + "'");
            }
          }
        }
      } else {
        // Block body ({ ... })
        if (expectedRet && expectedRet->name != "void" &&
            expectedRet->kind != TypeKind::Error &&
            !expectedRet->isGenericParam()) {
          if (!m_hasReturnStmt) {
            error(fDecl->loc, "Function '" + fDecl->name +
                                  "' expects a return value of type '" +
                                  expectedRet->toString() +
                                  "' but none was provided");
          }
        }
      }
    } else {
      // Bodiless / prototype function declaration (e.g. FFI, forward
      // declarations)
      fDecl->inferredType = Type::makeFunction(pTypes, expectedRet);
    }

    m_hasReturnStmt = oldHasReturn;
    m_currentReturnType = oldRet;
    m_disallowCustomOperators = oldDisallowCustomOperators;
    m_symbolTable.exitScope();
  } else if (decl) {
    for (const auto& attr : decl->attributes) {
      for (const auto& arg : attr.args) {
        if (arg.value) {
          checkExpression(arg.value);
        }
      }
    }
  }
}

void TypeChecker::checkStatement(StmtPtr stmt) {
  if (!stmt) return;

  if (auto sbStmt = std::dynamic_pointer_cast<StructuralBindingStmtAST>(stmt)) {
    for (const auto& attr : sbStmt->attributes) {
      for (const auto& arg : attr.args) {
        if (arg.value) {
          checkExpression(arg.value);
        }
      }
    }

    if (!sbStmt->initializer) {
        error(sbStmt->loc, "Structural binding used without a rvalue expression");
        return;
    }
    TypePtr initType = checkExpression(sbStmt->initializer);

    if (!initType || initType->kind == TypeKind::Error) {
        return;
    }

    TypePtr structuralType = initType->underlyingType();
    if (!structuralType) {
        structuralType = initType;
    }

    if (!structuralType->isTuple() && !structuralType->isStruct() &&
        !structuralType->isArray() && !structuralType->isSlice() &&
        !structuralType->isUnion()) {
        error(sbStmt->loc, "Structural binding cannnot be used for non structured type. Found type `" + initType->toString() + "`. ");
        return;
    }

    auto symbols = sbStmt->symbols;

    if (structuralType->isStruct() && structuralType->fields.empty()) {
        auto declaration = m_allStructDecls.find(structuralType->name);
        if (declaration != m_allStructDecls.end() && declaration->second) {
            auto structDecl = declaration->second;
            m_symbolTable.enterScope();
            for (size_t i = 0;
                 i < structDecl->typeParams.size() &&
                 i < structuralType->typeArgs.size();
                 ++i) {
                m_symbolTable.defineType(structDecl->typeParams[i],
                                         structuralType->typeArgs[i]);
            }
            for (const auto& field : structDecl->fields) {
                structuralType->fields.push_back(
                    {field.name, resolveTypeAST(field.typeAst)});
            }
            m_symbolTable.exitScope();
        }
    }

    if (structuralType->isTuple()) {
        if (symbols.size() > structuralType->tupleElementTypes.size()) {
            error(sbStmt->loc, "Too many symbols provided on the left side of assignment. Tuple only has " + std::to_string(structuralType->tupleElementTypes.size()) + " elements");
            return;
        }

        for (size_t i = 0; i < symbols.size(); ++i) {
            TypePtr type = structuralType->tupleElementTypes[i];
            m_symbolTable.defineVar(symbols[i], type, sbStmt->isConst,
                                    sbStmt->isStatic);
        }
    }

    if (structuralType->isStruct() || structuralType->isUnion()) {
        if (structuralType->fields.empty()) {
            error(sbStmt->loc,
                  "Cannot structurally bind type `" + initType->toString() +
                      "` because its fields are not available");
            return;
        }
        if (symbols.size() > structuralType->fields.size()) {
            error(sbStmt->loc, "Too many symbols provided on the left side of assignment. Struct/Union only has " + std::to_string(structuralType->fields.size()) + " fields");
            return;
        }

        for (size_t i = 0; i < symbols.size(); ++i) {
            TypePtr fieldType = structuralType->fields[i].type;
            m_symbolTable.defineVar(symbols[i], fieldType, sbStmt->isConst,
                                    sbStmt->isStatic);
        }
    }

    if (structuralType->isArray() || structuralType->isSlice()) {
        if (structuralType->isArray() &&
            symbols.size() > static_cast<size_t>(structuralType->arraySize)) {
            error(sbStmt->loc, "Too many symbols provided on the left side of assignment. Array has the size " + std::to_string(structuralType->arraySize));
            return;
        }

        for (size_t i = 0; i < symbols.size(); ++i) {
            m_symbolTable.defineVar(symbols[i], structuralType->elementType,
                                    sbStmt->isConst, sbStmt->isStatic);
        }
    }
  } else if (auto vStmt = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
    for (const auto& attr : vStmt->attributes) {
      for (const auto& arg : attr.args) {
        if (arg.value) {
          checkExpression(arg.value);
        }
      }
    }
    TypePtr declType =
        vStmt->typeAst ? resolveTypeAST(vStmt->typeAst) : nullptr;
    TypePtr expectedInitType =
        declType && declType->name != "auto" ? declType : nullptr;
    TypePtr initType = nullptr;

    bool runtimeSizedArray =
        vStmt->typeAst && vStmt->typeAst->isRuntimeSizedArray &&
        (!declType || !declType->isHashMap());
    if (runtimeSizedArray) {
      TypePtr sizeType = checkExpression(vStmt->typeAst->arraySizeExpr);
      if (!isIntegerType(sizeType)) {
        error(vStmt->typeAst->loc,
              "Runtime array size must have an integer type");
      }
    }

    if (vStmt->initializer) {
      if (auto arrLit = std::dynamic_pointer_cast<ArrayLiteralExprAST>(
              vStmt->initializer)) {
        initType = checkArrayLiteralExpr(arrLit, expectedInitType);
      } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(
                     vStmt->initializer)) {
        initType = checkMapLiteralExpr(mapLit, expectedInitType);
      } else {
        initType = checkExpression(vStmt->initializer, expectedInitType);
      }
    }

    if (!declType || declType->name == "auto") {
      if (initType) {
        declType = initType;
      } else {
        error(vStmt->loc, "Cannot infer type for 'auto' variable '" +
                              vStmt->name + "' without initializer");
        declType = Type::makeError();
      }
    } else if (initType && !declType->isGenericParam()) {
      // Type check assignment compatibility
      const bool initializesCorePointerWithNull =
          std::dynamic_pointer_cast<NullLiteralExprAST>(vStmt->initializer) &&
          isCoreManagedType(declType);
      if (!isAssignable(initType, declType) &&
          !initializesCorePointerWithNull) {
        error(vStmt->loc, "Cannot initialize variable '" + vStmt->name +
                              "' of type '" + declType->toString() +
                              "' with expression of type '" +
                              initType->toString() + "'");
      }
    }

    vStmt->inferredType = declType;
    if (declType && declType->kind != TypeKind::Error &&
        !runtimeSizedArray) {
      vStmt->typeAst = makeTypeASTFromType(declType, vStmt->loc);
    }
    m_symbolTable.defineVar(vStmt->name, declType, vStmt->isConst,
                            vStmt->isStatic);

  } else if (auto eStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
    eStmt->inferredType = checkExpression(eStmt->expr);
  } else if (auto rStmt = std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
    m_hasReturnStmt = true;
    TypePtr retValType = Type::makePrimitive("void");
    if (rStmt->value) {
      retValType = checkExpression(rStmt->value, m_currentReturnType);
    }
    rStmt->inferredType = retValType;

    if (m_currentReturnType && m_currentReturnType->kind != TypeKind::Error &&
        !m_currentReturnType->isGenericParam()) {
      if (m_currentReturnType->name == "void" && retValType->name != "void" &&
          retValType->kind != TypeKind::Error) {
        error(rStmt->loc,
              "Cannot return a value from a function returning 'void'");
      } else if (m_currentReturnType->name != "void") {
        if (!isAssignable(retValType, m_currentReturnType)) {
          error(rStmt->loc, "Return type mismatch: cannot convert '" +
                                retValType->toString() + "' to '" +
                                m_currentReturnType->toString() + "'");
        }
      }
    } else if (!m_currentReturnType) {
      m_currentReturnType = retValType;
    }
  } else if (auto yStmt = std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
    if (yStmt->value) {
      TypePtr expectedYieldType =
          m_expectedYieldType ? m_expectedYieldType : m_currentYieldType;
      yStmt->inferredType = checkExpression(yStmt->value, expectedYieldType);
      m_currentYieldType = yStmt->inferredType;
    }
  } else if (auto bStmt = std::dynamic_pointer_cast<BreakStmtAST>(stmt)) {
    if (m_loopDepth == 0) {
      error(bStmt->loc, "'break' statement outside of loop");
    }
  } else if (auto cStmt = std::dynamic_pointer_cast<ContinueStmtAST>(stmt)) {
    if (m_loopDepth == 0) {
      error(cStmt->loc, "'continue' statement outside of loop");
    }
  } else if (auto whileStmt = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
    checkWhileStmt(whileStmt);
  } else if (auto doWhileStmt =
                 std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
    checkDoWhileStmt(doWhileStmt);
  } else if (auto forStmt = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
    checkForStmt(forStmt);
  } else if (auto dStmt = std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
    if (dStmt->deferredStmt) {
      checkStatement(dStmt->deferredStmt);
    }
  } else if (auto taStmt = std::dynamic_pointer_cast<TypeAliasStmtAST>(stmt)) {
    if (taStmt->decl) {
      m_symbolTable.defineTypeAlias(taStmt->decl->aliasName, taStmt->decl);
    }
  }
}

void TypeChecker::checkWhileStmt(std::shared_ptr<WhileStmtAST> stmt) {
  if (!stmt) return;
  if (stmt->condition) {
    checkExpression(stmt->condition);
  }
  if (stmt->body) {
    m_loopDepth++;
    checkStatement(stmt->body);
    m_loopDepth--;
  }
}

void TypeChecker::checkDoWhileStmt(std::shared_ptr<DoWhileStmtAST> stmt) {
  if (!stmt) return;
  if (stmt->body) {
    m_loopDepth++;
    checkStatement(stmt->body);
    m_loopDepth--;
  }
  if (stmt->condition) {
    checkExpression(stmt->condition);
  }
}

void TypeChecker::checkForStmt(std::shared_ptr<ForStmtAST> stmt) {
  if (!stmt) return;
  m_symbolTable.enterScope();
  if (stmt->init) {
    checkStatement(stmt->init);
  }
  if (stmt->condition) {
    checkExpression(stmt->condition);
  }
  if (stmt->post) {
    checkExpression(stmt->post);
  }
  if (stmt->body) {
    m_loopDepth++;
    checkStatement(stmt->body);
    m_loopDepth--;
  }
  m_symbolTable.exitScope();
}

TypePtr TypeChecker::checkExpression(ExprPtr expr, TypePtr expectedType) {
  if (!expr) return Type::makePrimitive("void");

  // Overload resolution re-visits operand expressions while matching each
  // candidate. A fully checked expression already has a concrete type, so
  // reuse it when there is no expected type that could refine a generic or
  // literal. Without this, a left-associative operator chain `a << b << c`
  // is re-checked once per candidate per level and grows exponentially.
  if (!expectedType && expr->inferredType &&
      expr->inferredType->kind != TypeKind::Error &&
      !expr->inferredType->isUnknown()) {
    return expr->inferredType;
  }

  TypePtr type = Type::makeError();

  if (auto intLit = std::dynamic_pointer_cast<IntegerLiteralExprAST>(expr)) {
    type = Type::makePrimitive("int");
  } else if (auto fltLit =
                 std::dynamic_pointer_cast<FloatLiteralExprAST>(expr)) {
    if (!fltLit->value.empty() &&
        (fltLit->value.back() == 'f' || fltLit->value.back() == 'F')) {
      type = Type::makePrimitive("float");
    } else {
      type = Type::makePrimitive("double");
    }
  } else if (auto strLit =
                 std::dynamic_pointer_cast<StringLiteralExprAST>(expr)) {
    type = Type::makePointer(Type::makePrimitive("char"), true);
  } else if (auto charLit =
                 std::dynamic_pointer_cast<CharLiteralExprAST>(expr)) {
    type = Type::makePrimitive("char");
  } else if (auto boolLit =
                 std::dynamic_pointer_cast<BoolLiteralExprAST>(expr)) {
    type = Type::makePrimitive("bool");
  } else if (auto nullLit =
                 std::dynamic_pointer_cast<NullLiteralExprAST>(expr)) {
    type = checkNullLiteralExpr(nullLit);
  } else if (auto ident = std::dynamic_pointer_cast<IdentifierExprAST>(expr)) {
    Symbol* sym = m_symbolTable.lookupVar(ident->name);
    if (sym) {
      type = sym->type;
    } else {
      auto funcs = m_symbolTable.lookupFunctions(ident->name);
      if (!funcs.empty() && funcs[0]->type) {
        type = funcs[0]->type;
      } else {
        error(ident->loc, "Undeclared identifier '" + ident->name + "'");
      }
    }
  } else if (auto scopedIdent =
                 std::dynamic_pointer_cast<ScopedIdentifierExprAST>(expr)) {
    std::string fullName =
        scopedIdent->scopeName + "::" + scopedIdent->memberName;
    Symbol* varSym = m_symbolTable.lookupVar(fullName);
    if (varSym && varSym->type) {
      type = varSym->type;
    } else {
      Symbol* enumSym = m_symbolTable.lookupType(scopedIdent->scopeName);
      if (enumSym && enumSym->type && enumSym->type->isEnum()) {
        bool found = false;
        for (const auto& enumItem : enumSym->type->enumerators) {
          if (enumItem == scopedIdent->memberName) {
            found = true;
            break;
          }
        }
        if (found) {
          type = enumSym->type;
        } else {
          error(scopedIdent->loc, "Enum '" + scopedIdent->scopeName +
                                      "' has no member named '" +
                                      scopedIdent->memberName + "'");
          type = Type::makeError();
        }
      } else {
        error(scopedIdent->loc,
              "Unknown scope, variable, or enum member '" + fullName + "'");
        type = Type::makeError();
      }
    }
  } else if (auto binExpr = std::dynamic_pointer_cast<BinaryExprAST>(expr)) {
    type = checkBinaryExpr(binExpr);
  } else if (auto arrLit =
                 std::dynamic_pointer_cast<ArrayLiteralExprAST>(expr)) {
    type = checkArrayLiteralExpr(arrLit, expectedType);
  } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(expr)) {
    type = checkMapLiteralExpr(mapLit, expectedType);
  } else if (auto idxExpr = std::dynamic_pointer_cast<IndexExprAST>(expr)) {
    type = checkIndexExpr(idxExpr);
  } else if (auto slcExpr = std::dynamic_pointer_cast<SliceExprAST>(expr)) {
    type = checkSliceExpr(slcExpr);
  } else if (auto unExpr = std::dynamic_pointer_cast<UnaryExprAST>(expr)) {
    type = checkUnaryExpr(unExpr);
  }else if (auto unExpr = std::dynamic_pointer_cast<PostfixUnaryExprAST>(expr)) {
    type = checkPostfixUnaryExpr(unExpr);
  }  else if (auto callExpr = std::dynamic_pointer_cast<CallExprAST>(expr)) {
    type = checkCallExpr(callExpr, expectedType);
  } else if (auto smCall =
                 std::dynamic_pointer_cast<StaticMethodCallExprAST>(expr)) {
    type = checkStaticMethodCallExpr(smCall, expectedType);
  } else if (auto memAcc =
                 std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) {
    type = checkMemberAccessExpr(memAcc);
  } else if (auto stInit = std::dynamic_pointer_cast<StructInitExprAST>(expr)) {
    type = checkStructInitExpr(stInit, expectedType);
  } else if (auto ifExpr = std::dynamic_pointer_cast<IfExprAST>(expr)) {
    type = checkIfExpr(ifExpr, expectedType);
  } else if (auto swExpr = std::dynamic_pointer_cast<SwitchExprAST>(expr)) {
    type = checkSwitchExpr(swExpr, expectedType);
  } else if (auto blkExpr = std::dynamic_pointer_cast<BlockExprAST>(expr)) {
    type = checkBlockExpr(blkExpr, expectedType);
  } else if (auto clsExpr = std::dynamic_pointer_cast<ClosureExprAST>(expr)) {
    type = checkClosureExpr(clsExpr);
  } else if (auto assExpr = std::dynamic_pointer_cast<AssignExprAST>(expr)) {
    type = checkAssignExpr(assExpr);
  } else if (auto castExpr = std::dynamic_pointer_cast<CastExprAST>(expr)) {
    type = checkCastExpr(castExpr);
  } else if (auto tupExpr =
                 std::dynamic_pointer_cast<TupleLiteralExprAST>(expr)) {
    type = checkTupleLiteralExpr(tupExpr, expectedType);
  } else if (auto yieldExpr = std::dynamic_pointer_cast<YieldExprAST>(expr)) {
    type = checkExpression(yieldExpr->yieldedExpr, expectedType);
  }

  expr->inferredType = type;
  return type;
}

static bool isNumericPrimitive(TypePtr t) {
  if (!t) return false;
  t = t->underlyingType();
  if (!t || !t->isPrimitive()) return false;
  const std::string& n = t->name;
  return n == "int" || n == "uint" || n == "short" || n == "ushort" ||
         n == "long" || n == "ulong" || n == "size_t" || n == "char" ||
         n == "uchar" || n == "float" || n == "double";
}

static bool isIntegerPrimitive(TypePtr t) {
  if (!t) return false;
  t = t->underlyingType();
  if (!t || !t->isPrimitive()) return false;
  const std::string& n = t->name;
  return n == "int" || n == "uint" || n == "short" || n == "ushort" ||
         n == "long" || n == "ulong" || n == "size_t" || n == "char" ||
         n == "uchar" || n == "bool";
}

static bool isAggregateType(TypePtr t) {
  if (!t) return false;
  return t->isStruct() || t->isUnion() || t->isArray() || t->isSlice() ||
         t->isHashMap() || t->isTuple() || t->isFunction() || t->isClosure();
}

bool TypeChecker::resolveOperatorOverload(
    const std::string& symbol, const std::string& kind,
    const std::vector<ExprPtr>& arguments, const Location& loc,
    bool reportMismatch, TypePtr& resultType,
    std::shared_ptr<CallExprAST>& resolvedCall,
    bool& customOperatorDisabled) {
  resolvedCall = nullptr;
  resultType = nullptr;
  customOperatorDisabled = false;

  std::vector<Symbol*> candidates;
  for (Symbol* symbolEntry : m_symbolTable.lookupFunctions(symbol)) {
    if (!symbolEntry || !symbolEntry->funcAST) continue;
    if (!hasAttribute(symbolEntry->funcAST->attributes, kind + "_operator")) {
      continue;
    }
    candidates.push_back(symbolEntry);
  }
  if (candidates.empty()) return false;

  auto callExpr = std::make_shared<CallExprAST>(
      loc, std::make_shared<IdentifierExprAST>(loc, symbol),
      std::vector<TypeASTPtr>{}, arguments);
  callExpr->operatorKind = kind;

  FunctionOverloadMatch match =
      findBestDirectFunctionOverload(callExpr, candidates, nullptr);
  if (match.function) {
    if (m_disallowCustomOperators) {
      customOperatorDisabled = true;
      return false;
    }
    resultType = applyMatchedFunctionCall(callExpr, match.function,
                                           match.bindings);
    resolvedCall = std::move(callExpr);
    return true;
  }

  if (reportMismatch) {
    reportDirectCallMismatchErrors(callExpr, candidates.front(), symbol);
  }
  resultType = Type::makeError();
  return true;
}

TypePtr TypeChecker::checkBinaryExpr(std::shared_ptr<BinaryExprAST> expr) {
  TypePtr lType = checkExpression(expr->left);
  TypePtr rType = checkExpression(expr->right);

  TypePtr overloadedType;
  std::shared_ptr<CallExprAST> overloadedCall;
  bool customOperatorDisabled = false;
  // A null literal is not a `const char*`, so content-comparing string
  // operators (and other pointer-taking operators) must not capture checks
  // like `rng == nullptr`. Falling through to the built-in comparison emits a
  // plain pointer comparison that works for every pointer type.
  const bool comparesWithNull =
      (expr->op == "==" || expr->op == "!=") &&
      (std::dynamic_pointer_cast<NullLiteralExprAST>(expr->left) ||
       std::dynamic_pointer_cast<NullLiteralExprAST>(expr->right));
  if (!comparesWithNull &&
      resolveOperatorOverload(expr->op, "infix",
                              {expr->left, expr->right}, expr->loc, false,
                              overloadedType, overloadedCall,
                              customOperatorDisabled) &&
      overloadedCall) {
    expr->targetMangledName = overloadedCall->targetMangledName;
    expr->targetParamTypes = overloadedCall->targetParamTypes;
    expr->targetReturnType = overloadedCall->targetReturnType;
    expr->isOverloadedOperator = true;
    return overloadedType;
  }

  const size_t errorCount = m_result.errors.size();
  TypePtr builtInType = checkBinaryOperation(
      expr->op, lType, rType, expr->loc,
      static_cast<bool>(
          std::dynamic_pointer_cast<NullLiteralExprAST>(expr->left)),
      static_cast<bool>(
          std::dynamic_pointer_cast<NullLiteralExprAST>(expr->right)));
  if (customOperatorDisabled && builtInType &&
      builtInType->kind == TypeKind::Error) {
    m_result.errors.resize(errorCount);
    error(expr->loc, "Custom infix operator '" + expr->op +
                         "' is disabled by [[no_custom_operators]]");
    return Type::makeError();
  }
  return builtInType;
}

TypePtr TypeChecker::checkBinaryOperation(const std::string& op, TypePtr lType,
                                          TypePtr rType,
                                          const Location& loc,
                                          bool leftIsNull,
                                          bool rightIsNull) {
  if (!lType || !rType) return Type::makeError();
  if (lType->kind == TypeKind::Error || rType->kind == TypeKind::Error)
    return Type::makeError();

  if (op == "==" || op == "!=") {
    const bool comparesCorePointerWithNull =
        (leftIsNull && isCoreManagedType(rType)) ||
        (rightIsNull && isCoreManagedType(lType));
    if (isAggregateType(lType) || isAggregateType(rType)) {
      if (!lType->equals(rType) && !comparesCorePointerWithNull) {
        error(loc, "Cannot compare incompatible aggregate types '" +
                             lType->toString() + "' and '" + rType->toString() +
                             "'");
        return Type::makeError();
      }
    }
    return Type::makePrimitive("bool");
  }

  if (op == "<" || op == "<=" || op == ">" || op == ">=") {
    if (isAggregateType(lType) || isAggregateType(rType)) {
      error(loc, "Cannot perform relational comparison '" + op +
                           "' on aggregate types '" + lType->toString() +
                           "' and '" + rType->toString() + "'");
      return Type::makeError();
    }
    return Type::makePrimitive("bool");
  }

  if (op == "&&" || op == "||") {
    if (isAggregateType(lType) || isAggregateType(rType)) {
      error(loc,
            "Cannot perform logical operator '" + op + "' on aggregate types");
      return Type::makeError();
    }
    return Type::makePrimitive("bool");
  }

  if (op == "+") {
    if (lType->isPointer() && isIntegerPrimitive(rType)) return lType;
    if (isIntegerPrimitive(lType) && rType->isPointer()) return rType;
    if (isNumericPrimitive(lType) && isNumericPrimitive(rType)) {
      if (lType->name == "double" || rType->name == "double")
        return Type::makePrimitive("double");
      if (lType->name == "float" || rType->name == "float")
        return Type::makePrimitive("float");
      if (lType->name == "long" || rType->name == "long")
        return Type::makePrimitive("long");
      if (lType->name == "ulong" || rType->name == "ulong")
        return Type::makePrimitive("ulong");
      return Type::makePrimitive("int");
    }
    error(loc, "Invalid binary '+' on types '" + lType->toString() +
                         "' and '" + rType->toString() + "'");
    return Type::makeError();
  }

  if (op == "-") {
    if (lType->isPointer() && isIntegerPrimitive(rType)) return lType;
    if (lType->isPointer() && rType->isPointer() &&
        lType->pointerBase->equals(rType->pointerBase))
      return Type::makePrimitive("long");
    if (isNumericPrimitive(lType) && isNumericPrimitive(rType)) {
      if (lType->name == "double" || rType->name == "double")
        return Type::makePrimitive("double");
      if (lType->name == "float" || rType->name == "float")
        return Type::makePrimitive("float");
      if (lType->name == "long" || rType->name == "long")
        return Type::makePrimitive("long");
      if (lType->name == "ulong" || rType->name == "ulong")
        return Type::makePrimitive("ulong");
      return Type::makePrimitive("int");
    }
    error(loc, "Invalid binary '-' on types '" + lType->toString() +
                         "' and '" + rType->toString() + "'");
    return Type::makeError();
  }

  if (op == "*" || op == "/" || op == "%") {
    if (isNumericPrimitive(lType) && isNumericPrimitive(rType)) {
      if (lType->name == "double" || rType->name == "double")
        return Type::makePrimitive("double");
      if (lType->name == "float" || rType->name == "float")
        return Type::makePrimitive("float");
      if (lType->name == "long" || rType->name == "long")
        return Type::makePrimitive("long");
      if (lType->name == "ulong" || rType->name == "ulong")
        return Type::makePrimitive("ulong");
      return Type::makePrimitive("int");
    }
    error(loc, "Invalid operator '" + op + "' on types '" +
                         lType->toString() + "' and '" + rType->toString() +
                         "'");
    return Type::makeError();
  }

  if (op == "&" || op == "|" || op == "^" || op == "<<" || op == ">>") {
    if (isIntegerPrimitive(lType) && isIntegerPrimitive(rType)) {
      return lType;
    }
    error(loc,
          "Bitwise operator '" + op + "' requires integer operands, got '" +
              lType->toString() + "' and '" + rType->toString() + "'");
    return Type::makeError();
  }

  error(loc, "Unsupported binary operator '" + op + "' on types '" +
                       lType->toString() + "' and '" + rType->toString() + "'");
  return Type::makeError();
}

bool TypeChecker::isCoreManagedType(TypePtr type) const {
  TypePtr normalized = type ? type->underlyingType() : nullptr;
  if (!normalized || !normalized->isStruct()) return false;
  if (isCoreListType(normalized)) return false;
  if (isCoreLazyType(normalized)) return false;
  auto declaration = m_allStructDecls.find(normalized->name);
  return declaration != m_allStructDecls.end() &&
         hasAttribute(declaration->second->attributes, "core");
}

bool TypeChecker::isCoreListType(TypePtr type) const {
  TypePtr normalized = type ? type->underlyingType() : nullptr;
  if (!normalized || normalized->name != "List" || !normalized->isStruct()) {
    return false;
  }
  auto declaration = m_allStructDecls.find(normalized->name);
  return declaration != m_allStructDecls.end() &&
         hasAttribute(declaration->second->attributes, "core");
}

// The standard `List<T>` is implemented in Glang as an owner-backed dynamic
// array. The compiler still gives it index syntax and `.length` support so
// existing container and range code keeps working.
bool TypeChecker::isStdListType(TypePtr type) const {
  TypePtr normalized = type ? type->underlyingType() : nullptr;
  return normalized && normalized->name == "List" &&
         normalized->isStruct() && normalized->typeArgs.size() == 1;
}

bool TypeChecker::isCoreLazyType(TypePtr type) const {
  TypePtr normalized = type ? type->underlyingType() : nullptr;
  if (!normalized || normalized->name != "Lazy" || !normalized->isStruct()) {
    return false;
  }
  auto declaration = m_allStructDecls.find(normalized->name);
  return declaration != m_allStructDecls.end() &&
         hasAttribute(declaration->second->attributes, "core");
}


TypePtr TypeChecker::checkPostfixUnaryExpr(std::shared_ptr<PostfixUnaryExprAST> expr) {
    TypePtr subType = checkExpression(expr->operand);

    TypePtr overloadedType;
    std::shared_ptr<CallExprAST> overloadedCall;
    bool customOperatorDisabled = false;
    if (resolveOperatorOverload(expr->op, "postfix", {expr->operand},
                                expr->loc, false, overloadedType,
                                overloadedCall, customOperatorDisabled) &&
        overloadedCall) {
        expr->targetMangledName = overloadedCall->targetMangledName;
        expr->targetParamTypes = overloadedCall->targetParamTypes;
        expr->targetReturnType = overloadedCall->targetReturnType;
        expr->isOverloadedOperator = true;
        return overloadedType;
    }

    if ((expr->op == "++" || expr->op == "--") && (isNumericPrimitive(subType) || subType->isPointer())) {
        return subType;
    }
    if (customOperatorDisabled) {
        error(expr->loc, "Custom postfix operator '" + expr->op +
                             "' is disabled by [[no_custom_operators]]");
        return Type::makeError();
    }
    error(expr->loc, "Unsupported postfix operator '" + expr->op + "' on type `" + subType->toString() + "`");
    return Type::makeError();
}


TypePtr TypeChecker::checkUnaryExpr(std::shared_ptr<UnaryExprAST> expr) {
  if (expr->op == "sizeof") {
    if (expr->typeOperand) {
      TypePtr t = resolveTypeAST(expr->typeOperand);
      if (!t || t->kind == TypeKind::Error) {
        error(expr->loc, "Invalid type in sizeof");
        return Type::makeError();
      }
      expr->typeOperand = makeTypeASTFromType(t, expr->loc);
      return Type::makePrimitive("ulong");
    } else if (expr->operand) {
      if (auto ident =
              std::dynamic_pointer_cast<IdentifierExprAST>(expr->operand)) {
        Symbol* typeSym = m_symbolTable.lookupType(ident->name);
        if (typeSym) {
          return Type::makePrimitive("ulong");
        }
      }
      TypePtr subType = checkExpression(expr->operand);
      if (!subType || subType->kind == TypeKind::Error)
        return Type::makeError();
      return Type::makePrimitive("ulong");
    }
    return Type::makePrimitive("ulong");
  }

  TypePtr subType = checkExpression(expr->operand);
  if (!subType || subType->kind == TypeKind::Error) return Type::makeError();

  TypePtr overloadedType;
  std::shared_ptr<CallExprAST> overloadedCall;
  bool customOperatorDisabled = false;
  if (resolveOperatorOverload(expr->op, "prefix", {expr->operand}, expr->loc,
                              false, overloadedType, overloadedCall,
                              customOperatorDisabled) &&
      overloadedCall) {
    expr->targetMangledName = overloadedCall->targetMangledName;
    expr->targetParamTypes = overloadedCall->targetParamTypes;
    expr->targetReturnType = overloadedCall->targetReturnType;
    expr->isOverloadedOperator = true;
    return overloadedType;
  }

  auto index_ast = std::dynamic_pointer_cast<IndexExprAST>(expr->operand);
  if (expr->op == "&" && index_ast && index_ast->target->inferredType->isHashMap()) {
    return Type::makePointer(index_ast->target->inferredType->elementType, false);
  } else if (expr->op == "&") {
    return Type::makePointer(subType, false);
  }

  if (expr->op == "*") {
    if (subType->isPointer() && subType->pointerBase) {
      return subType->pointerBase;
    }
    if (isCoreManagedType(subType) &&
        subType->typeArgs.size() == 1) {
      return subType->typeArgs.front();
    }
    if (customOperatorDisabled) {
      error(expr->loc, "Custom prefix operator '" + expr->op +
                           "' is disabled by [[no_custom_operators]]");
      return Type::makeError();
    }
    error(expr->loc,
          "Cannot dereference non-pointer type '" + subType->toString() + "'");
    return Type::makeError();
  }
  if (expr->op == "!") {
    if (isAggregateType(subType)) {
      if (customOperatorDisabled) {
        error(expr->loc, "Custom prefix operator '" + expr->op +
                             "' is disabled by [[no_custom_operators]]");
        return Type::makeError();
      }
      error(expr->loc, "Cannot apply '!' operator to aggregate type '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    return Type::makePrimitive("bool");
  }
  if (expr->op == "~") {
    if (!isIntegerPrimitive(subType)) {
      if (customOperatorDisabled) {
        error(expr->loc, "Custom prefix operator '" + expr->op +
                             "' is disabled by [[no_custom_operators]]");
        return Type::makeError();
      }
      error(expr->loc, "Bitwise NOT '~' requires integer type, got '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    return subType;
  }
  if (expr->op == "-" || expr->op == "+") {
    if (!isNumericPrimitive(subType)) {
      if (customOperatorDisabled) {
        error(expr->loc, "Custom prefix operator '" + expr->op +
                             "' is disabled by [[no_custom_operators]]");
        return Type::makeError();
      }
      error(expr->loc, "Unary operator '" + expr->op +
                           "' requires numeric type, got '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    return subType;
  }
  if (expr->op == "++" || expr->op == "--" || expr->op == "post++" ||
      expr->op == "post--") {
    if (!isNumericPrimitive(subType) && !subType->isPointer()) {
      if (customOperatorDisabled) {
        error(expr->loc, "Custom prefix operator '" + expr->op +
                             "' is disabled by [[no_custom_operators]]");
        return Type::makeError();
      }
      error(expr->loc, "Increment/decrement operator '" + expr->op +
                           "' requires numeric or pointer type, got '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    if (customOperatorDisabled) {
      error(expr->loc, "Custom prefix operator '" + expr->op +
                           "' is disabled by [[no_custom_operators]]");
      return Type::makeError();
    }
    return subType;
  }

  return subType;
}

bool TypeChecker::deduceTemplateArgs(TypePtr paramType, TypePtr argType, std::map<std::string, TypePtr>& bindings) {
  if (!paramType || !argType) return false;

  TypePtr effParam = paramType;
  if (effParam->kind == TypeKind::Alias && effParam->aliasTarget) {
    effParam = effParam->aliasTarget->underlyingType();
    if (!effParam) effParam = paramType;
  }

  if (effParam->kind == TypeKind::GenericParam) {
    auto existing = bindings.find(effParam->name);
    if (existing == bindings.end() || !existing->second ||
        existing->second->kind == TypeKind::Unknown) {
      bindings[effParam->name] = argType;
      return true;
    }

    TypePtr boundType = existing->second;
    if (boundType->equals(argType)) return true;
    if (containsGenericParam(boundType) && !containsGenericParam(argType)) {
      existing->second = argType;
      return true;
    }
    if (!isAssignable(argType, boundType) &&
        isAssignable(boundType, argType)) {
      existing->second = argType;
    }
    return true;
  }

  TypePtr effArg = argType;
  if (effArg->kind == TypeKind::Alias && effArg->aliasTarget) {
    effArg = effArg->aliasTarget->underlyingType();
    if (!effArg) effArg = argType;
  }

  TypePtr funcPtrParam = (effParam->isPointer() && effParam->pointerBase &&
                          (effParam->pointerBase->isFunction() ||
                           effParam->pointerBase->isClosure()))
                             ? (effParam->pointerBase->underlyingType()
                                    ? effParam->pointerBase->underlyingType()
                                    : effParam->pointerBase)
                             : effParam;
  TypePtr funcPtrArg = (effArg->isPointer() && effArg->pointerBase &&
                        (effArg->pointerBase->isFunction() ||
                         effArg->pointerBase->isClosure()))
                           ? (effArg->pointerBase->underlyingType()
                                  ? effArg->pointerBase->underlyingType()
                                  : effArg->pointerBase)
                           : effArg;

  if (funcPtrParam->isPointer() && funcPtrArg->isPointer()) {
    return deduceTemplateArgs(funcPtrParam->pointerBase, funcPtrArg->pointerBase,
                              bindings);
  }

  if (funcPtrParam->isPointer() && !funcPtrArg->isPointer()) {
    return deduceTemplateArgs(funcPtrParam->pointerBase, funcPtrArg, bindings);
  }

  if (!funcPtrParam->isPointer() && funcPtrArg->isPointer()) {
    return deduceTemplateArgs(funcPtrParam, funcPtrArg->pointerBase, bindings);
  }

  if ((effParam->isArray() || effParam->isSlice()) &&
      (effArg->isArray() || effArg->isSlice())) {
    if (effParam->elementType && effArg->elementType) {
      return deduceTemplateArgs(effParam->elementType, effArg->elementType,
                                bindings);
    }
    return true;
  }

  if (effParam->isHashMap() && effArg->isHashMap()) {
    if (effParam->keyType && effArg->keyType) {
      deduceTemplateArgs(effParam->keyType, effArg->keyType, bindings);
    }
    if (effParam->elementType && effArg->elementType) {
      deduceTemplateArgs(effParam->elementType, effArg->elementType, bindings);
    }
    return true;
  }

  if (effParam->isTuple() && effArg->isTuple()) {
    if (effParam->tupleElementTypes.size() ==
        effArg->tupleElementTypes.size()) {
      for (size_t i = 0; i < effParam->tupleElementTypes.size(); ++i) {
        deduceTemplateArgs(effParam->tupleElementTypes[i],
                           effArg->tupleElementTypes[i], bindings);
      }
    }
    return true;
  }

  if ((effParam->isStruct() || effParam->isUnion()) &&
      (effArg->isStruct() || effArg->isUnion())) {
    if (effParam->name == effArg->name) {
      for (size_t i = 0;
           i < effParam->typeArgs.size() && i < effArg->typeArgs.size(); ++i) {
        deduceTemplateArgs(effParam->typeArgs[i], effArg->typeArgs[i],
                           bindings);
      }
    }
    return true;
  }

  if ((effParam->isFunction() || effParam->isClosure()) &&
      (effArg->isFunction() || effArg->isClosure())) {
    if (effParam->paramTypes.size() == effArg->paramTypes.size()) {
      for (size_t i = 0; i < effParam->paramTypes.size(); ++i) {
        deduceTemplateArgs(effParam->paramTypes[i], effArg->paramTypes[i],
                           bindings);
      }
    }
    if (effParam->returnType && effArg->returnType) {
      deduceTemplateArgs(effParam->returnType, effArg->returnType, bindings);
    }
    return true;
  }

  return true;
}

static TypePtr getVariadicExpectedParamType(bool isVariadic, size_t argIndex, size_t fixedArgCount,
                                            TypePtr variadicTarget, const std::vector<TypePtr>& argTypes,
                                            size_t paramTypeCount) {
  if (!isVariadic || argIndex < fixedArgCount || !variadicTarget) {
    return nullptr;
  }
  if (argIndex == fixedArgCount && argTypes.size() == paramTypeCount &&
      argTypes[argIndex] &&
      (argTypes[argIndex]->isArray() || argTypes[argIndex]->isSlice())) {
    return variadicTarget;
  }
  if (variadicTarget->isArray() || variadicTarget->isSlice()) {
    return variadicTarget->elementType;
  }
  return variadicTarget;
}

std::map<std::string, TypePtr> TypeChecker::collectExplicitTemplateBindings(
    std::shared_ptr<CallExprAST> expr,
    const std::shared_ptr<FunctionDeclAST>& funcAST) {
  std::map<std::string, TypePtr> bindings;
  if (!expr->templateArgs.empty() && funcAST) {
    for (size_t i = 0; i < expr->templateArgs.size() &&
                       i < funcAST->typeParams.size();
         ++i) {
      bindings[funcAST->typeParams[i]] =
          resolveTypeAST(expr->templateArgs[i]);
    }
  }
  return bindings;
}

bool TypeChecker::hasUnboundTemplateParams(
    const std::shared_ptr<FunctionDeclAST>& funcAST,
    const std::map<std::string, TypePtr>& bindings) {
  if (!funcAST) return false;
  for (const auto& tp : funcAST->typeParams) {
    if (bindings.find(tp) == bindings.end() || !bindings.at(tp) ||
        bindings.at(tp)->isUnknown()) {
      return true;
    }
  }
  return false;
}

bool TypeChecker::deduceTemplateArgsFromExpectedReturn(
    const std::shared_ptr<FunctionDeclAST>& funcAST,
    TypePtr functionReturnType, TypePtr expectedReturnType,
    std::map<std::string, TypePtr>& bindings) {
  if (!functionReturnType || !expectedReturnType ||
      expectedReturnType->isUnknown() || expectedReturnType->name == "auto") {
    return true;
  }

  std::map<std::string, TypePtr> inferredBindings = bindings;
  deduceTemplateArgs(functionReturnType, expectedReturnType, inferredBindings);
  if (funcAST) {
    for (const auto& typeParam : funcAST->typeParams) {
      if (bindings.find(typeParam) == bindings.end()) {
        auto inferred = inferredBindings.find(typeParam);
        if (inferred != inferredBindings.end() && inferred->second) {
          bindings[typeParam] = inferred->second;
        }
      }
    }
  }

  TypePtr resolvedReturnType = functionReturnType->substitute(bindings);
  return isAssignable(resolvedReturnType, expectedReturnType);
}

TypeChecker::FunctionOverloadMatch TypeChecker::findBestDirectFunctionOverload(
    std::shared_ptr<CallExprAST> expr, const std::vector<Symbol*>& funcs,
    TypePtr expectedReturnType) {
  FunctionOverloadMatch result;
  int maxScore = -1;

  for (Symbol* fnSym : funcs) {
    if (!fnSym->type || !fnSym->type->isFunction()) continue;
    auto fType = fnSym->type;
    bool isVariadic = fnSym->funcAST && !fnSym->funcAST->parameters.empty() &&
                      fnSym->funcAST->parameters.back().isVariadic;
    bool isCVariadic = isVariadic && isExternFunction(fnSym->funcAST.get());
    size_t fixedArgCount = isVariadic && !fType->paramTypes.empty()
                               ? fType->paramTypes.size() - 1
                               : fType->paramTypes.size();

    if ((isVariadic && expr->arguments.size() < fixedArgCount) ||
        (!isVariadic && expr->arguments.size() != fType->paramTypes.size())) {
      continue;
    }

    std::map<std::string, TypePtr> bindings =
        collectExplicitTemplateBindings(expr, fnSym->funcAST);

    std::vector<TypePtr> argTypes;
    bool variadicArgumentsValid = true;

    if (isVariadic && !fType->paramTypes.empty() &&
        fType->paramTypes.back() &&
        (fType->paramTypes.back()->isArray() ||
         fType->paramTypes.back()->isSlice())) {
      auto variadicType = fType->paramTypes.back();
      size_t var_args_start = fType->paramTypes.size() - 1;

      for (size_t i = 0; i < var_args_start; ++i) {
        TypePtr argT = checkExpression(expr->arguments[i]);
        argTypes.push_back(argT);
        if (fnSym->funcAST && i < fType->paramTypes.size()) {
          deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
        }
      }

      TypePtr expectedType = fType->paramTypes.back();
      TypePtr targetType = (expectedType->isArray() || expectedType->isSlice())
                               ? expectedType->elementType
                               : expectedType;
      std::vector<ExprPtr> variadicArgs;
      bool passedVariadicArray = false;
      TypePtr passedVariadicArrayType;
      if (isCVariadic) {
        for (size_t i = var_args_start; i < expr->arguments.size(); ++i) {
          TypePtr argType = checkExpression(expr->arguments[i]);
          argTypes.push_back(argType);
        }
      } else {
      auto explicitArrayLiteral =
          expr->arguments.size() == var_args_start + 1
              ? std::dynamic_pointer_cast<ArrayLiteralExprAST>(
                    expr->arguments.back())
              : nullptr;

      if (expr->arguments.size() == var_args_start + 1) {
        ExprPtr lastArg = expr->arguments.back();
        if (explicitArrayLiteral) {
          variadicArgs = explicitArrayLiteral->elements;
        } else {
          TypePtr lastType = checkExpression(lastArg);
          if (lastType && (lastType->isArray() || lastType->isSlice())) {
            passedVariadicArray = true;
            passedVariadicArrayType = lastType;
            deduceTemplateArgs(targetType, lastType->elementType, bindings);
            if (!isVariadicArgAssignable(
                    lastType, expectedType->substitute(bindings))) {
              variadicArgumentsValid = false;
            }
          } else {
            variadicArgs.push_back(lastArg);
          }
        }
      } else {
        for (size_t i = var_args_start; i < expr->arguments.size(); ++i) {
          variadicArgs.push_back(expr->arguments[i]);
        }
      }

      for (const auto& variadicArg : variadicArgs) {
        TypePtr argT = checkExpression(variadicArg);
        deduceTemplateArgs(targetType, argT, bindings);
        TypePtr concreteTarget = targetType->substitute(bindings);
        if (!isVariadicArgAssignable(argT, concreteTarget) &&
            !isDeferredGenericArgMatch(argT, concreteTarget)) {
          variadicArgumentsValid = false;
        }
      }
      argTypes.push_back(passedVariadicArray
                             ? passedVariadicArrayType
                             : expectedType);
      }
    } else {
      for (size_t i = 0; i < expr->arguments.size(); ++i) {
        TypePtr argT = checkExpression(expr->arguments[i]);
        argTypes.push_back(argT);
        if (fnSym->funcAST && i < fType->paramTypes.size()) {
          deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
        }
      }
    }

    if (!deduceTemplateArgsFromExpectedReturn(
            fnSym->funcAST, fType->returnType, expectedReturnType, bindings)) {
      continue;
    }

    if (hasUnboundTemplateParams(fnSym->funcAST, bindings)) continue;

    bool match = variadicArgumentsValid;
    int score = 0;
    for (size_t i = 0; i < argTypes.size(); ++i) {
      TypePtr expectedP = nullptr;
      if (isCVariadic && i >= fixedArgCount) {
        score += 1;
        continue;
      } else if (isVariadic && i >= fixedArgCount &&
                 !fType->paramTypes.empty()) {
        expectedP = getVariadicExpectedParamType(
            isVariadic, i, fixedArgCount, fType->paramTypes.back(), argTypes,
            fType->paramTypes.size());
      } else if (i < fType->paramTypes.size()) {
        expectedP = fType->paramTypes[i];
      }
      if (!expectedP ||
          (!isVariadicArgAssignable(argTypes[i],
                                    expectedP->substitute(bindings)) &&
           !isDeferredStructPointerMatch(argTypes[i], expectedP, bindings) &&
           !isDeferredGenericArgMatch(argTypes[i], expectedP->substitute(bindings)))) {
        match = false;
        break;
      }
      score += (argTypes[i] && expectedP &&
                argTypes[i]->equals(expectedP->substitute(bindings)))
                   ? 2
                   : 1;
    }

    if (match && score > maxScore) {
      maxScore = score;
      result.function = fnSym;
      result.bindings = bindings;
    }
  }

  return result;
}

std::vector<ExprPtr> TypeChecker::buildUfcsFullArguments(
    std::shared_ptr<MemberAccessExprAST> memAccess, TypePtr objType,
    const std::vector<ExprPtr>& callArgs, TypePtr functionType,
    bool isVariadic) {
  if (!functionType || !functionType->isFunction()) return {};

  auto fType = functionType;
  const size_t fixedArgCount =
      isVariadic && !fType->paramTypes.empty()
          ? fType->paramTypes.size() - 1
          : fType->paramTypes.size();
  if (!isVariadic && callArgs.size() == fType->paramTypes.size()) {
    return callArgs;
  }
  if ((isVariadic && callArgs.size() + 1 < fixedArgCount) ||
      (!isVariadic && callArgs.size() + 1 != fType->paramTypes.size())) {
    return {};
  }

  std::vector<ExprPtr> fullArgs;
  if (fType->paramTypes.size() > 0 && fType->paramTypes[0]->isPointer() &&
      !objType->isPointer()) {
    auto addrOf = std::make_shared<UnaryExprAST>(memAccess->object->loc, "&",
                                                 memAccess->object);
    addrOf->inferredType = Type::makePointer(objType);
    fullArgs.push_back(addrOf);
  } else if (fType->paramTypes.size() > 0 &&
             !fType->paramTypes[0]->isPointer() && objType->isPointer()) {
    auto deref = std::make_shared<UnaryExprAST>(memAccess->object->loc, "*",
                                                memAccess->object);
    deref->inferredType = objType->pointerBase;
    fullArgs.push_back(deref);
  } else {
    fullArgs.push_back(memAccess->object);
  }
  for (const auto& arg : callArgs) {
    fullArgs.push_back(arg);
  }
  return fullArgs;
}

TypeChecker::UfcsOverloadMatch TypeChecker::findBestUfcsFunctionOverload(
    std::shared_ptr<CallExprAST> expr, TypePtr objType,
    const std::vector<Symbol*>& funcs,
    std::shared_ptr<MemberAccessExprAST> memAccess,
    TypePtr expectedReturnType) {
  UfcsOverloadMatch result;
  int maxScore = -1;

  for (Symbol* fnSym : funcs) {
    if (!fnSym->type || !fnSym->type->isFunction()) continue;
    auto fType = fnSym->type;
    const bool isVariadic =
        fnSym->funcAST && !fnSym->funcAST->parameters.empty() &&
        fnSym->funcAST->parameters.back().isVariadic;
    const bool isCVariadic =
        isVariadic && isExternFunction(fnSym->funcAST.get());

    std::vector<ExprPtr> fullArgs =
        buildUfcsFullArguments(memAccess, objType, expr->arguments, fType,
                               isVariadic);
    if (fullArgs.empty()) continue;
    const size_t fixedArgCount =
        isVariadic && !fType->paramTypes.empty()
            ? fType->paramTypes.size() - 1
            : fType->paramTypes.size();
    if ((!isVariadic && fullArgs.size() != fType->paramTypes.size()) ||
        (isVariadic && fullArgs.size() < fixedArgCount)) {
      continue;
    }

    std::map<std::string, TypePtr> bindings =
        collectExplicitTemplateBindings(expr, fnSym->funcAST);

    bool match = true;
    int score = 0;
    // Prefer overloads whose receiver is passed through unchanged over ones
    // that require an implicit address-of or dereference. Without this bonus a
    // value overload (`to_upper(char)`) and a pointer overload
    // (`to_upper(const char*)`) can tie when the receiver is a pointer, and
    // the first registered function would win arbitrarily.
    const bool directReceiver =
        !fullArgs.empty() && fullArgs.front().get() == memAccess->object.get();
    std::vector<TypePtr> argTypes;
    for (size_t i = 0; i < fullArgs.size(); ++i) {
      TypePtr argT = checkExpression(fullArgs[i]);
      argTypes.push_back(argT);
      if (fnSym->funcAST && i < fixedArgCount) {
        deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
      } else if (isVariadic && !isCVariadic &&
                 i >= fixedArgCount && !fType->paramTypes.empty()) {
        TypePtr variadicType = fType->paramTypes.back();
        TypePtr elementType =
            variadicType && (variadicType->isArray() ||
                             variadicType->isSlice())
                ? variadicType->elementType
                : variadicType;
        const bool passedArray =
            i + 1 == fullArgs.size() && argT &&
            (argT->isArray() || argT->isSlice());
        deduceTemplateArgs(elementType,
                           passedArray ? argT->elementType : argT, bindings);
      }
    }

    if (!deduceTemplateArgsFromExpectedReturn(
            fnSym->funcAST, fType->returnType, expectedReturnType, bindings)) {
      continue;
    }

    if (hasUnboundTemplateParams(fnSym->funcAST, bindings)) continue;

    for (size_t i = 0; i < argTypes.size(); ++i) {
      if (isCVariadic && i >= fixedArgCount) {
        ++score;
        continue;
      }
      TypePtr expectedP =
          (i < fixedArgCount && fType->paramTypes[i])
              ? fType->paramTypes[i]->substitute(bindings)
              : nullptr;
      if (isVariadic && i >= fixedArgCount && !fType->paramTypes.empty()) {
        TypePtr variadicType = fType->paramTypes.back()->substitute(bindings);
        const bool passedArray =
            i + 1 == argTypes.size() && argTypes[i] &&
            (argTypes[i]->isArray() || argTypes[i]->isSlice());
        expectedP =
            passedArray
                ? variadicType
                : variadicType && (variadicType->isArray() ||
                                   variadicType->isSlice())
                      ? variadicType->elementType
                      : variadicType;
      }
      if (!expectedP ||
          (!isVariadicArgAssignable(argTypes[i], expectedP) &&
           (i >= fType->paramTypes.size() ||
            !isDeferredStructPointerMatch(argTypes[i], fType->paramTypes[i],
                                          bindings)) &&
           !isDeferredGenericArgMatch(argTypes[i], expectedP))) {
        match = false;
        break;
      }
      score +=
          (argTypes[i] && expectedP && argTypes[i]->equals(expectedP)) ? 2 : 1;
    }

    if (match && directReceiver) score += 1;

    if (match && score > maxScore) {
      maxScore = score;
      result.function = fnSym;
      result.bindings = bindings;
      result.fullArguments = fullArgs;
    }
  }

  return result;
}

TypePtr TypeChecker::resolveMatchedFunctionReturnType(
    Symbol* matchedFn, const std::map<std::string, TypePtr>& bindings) {
  if (matchedFn && matchedFn->funcAST) {
    m_symbolTable.enterScope();
    for (const auto& tp : matchedFn->funcAST->typeParams) {
      auto it = bindings.find(tp);
      if (it != bindings.end() && it->second)
        m_symbolTable.defineType(tp, it->second);
      else
        m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
    }
    TypePtr ret = matchedFn->funcAST->returnTypeAst
                      ? resolveTypeAST(matchedFn->funcAST->returnTypeAst)
                      : Type::makePrimitive("void");
    m_symbolTable.exitScope();
    return ret ? ret : Type::makePrimitive("void");
  }
  if (matchedFn && matchedFn->type && matchedFn->type->returnType) {
    return matchedFn->type->returnType->substitute(bindings);
  }
  return Type::makePrimitive("void");
}

void TypeChecker::setMatchedFunctionTarget(
    std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
    const std::map<std::string, TypePtr>& bindings) {
  if (!matchedFn) return;

  if (!matchedFn->mangledName.empty()) {
    expr->targetMangledName = matchedFn->mangledName;
  }
  if (matchedFn->funcAST) {
    std::string instMangled =
        instantiateFunction(matchedFn->funcAST, bindings, expr->loc);
    if (!instMangled.empty()) {
      expr->targetMangledName = instMangled;
    }
  }
}

void TypeChecker::packVariadicCallArguments(
    std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
    const std::map<std::string, TypePtr>& bindings) {
  if (!matchedFn || !matchedFn->funcAST ||
      matchedFn->funcAST->parameters.empty() ||
      !matchedFn->funcAST->parameters.back().isVariadic ||
      isExternFunction(matchedFn->funcAST.get())) {
    return;
  }

  size_t fixedArgCount = matchedFn->funcAST->parameters.size() - 1;
  bool explicitVariadicArray =
      matchedFn->type &&
      expr->arguments.size() == matchedFn->type->paramTypes.size() &&
      !expr->arguments.empty() &&
      (std::dynamic_pointer_cast<ArrayLiteralExprAST>(expr->arguments.back()) ||
       (expr->arguments.back()->inferredType &&
        (expr->arguments.back()->inferredType->isArray() ||
         expr->arguments.back()->inferredType->isSlice())));

  if (expr->arguments.size() < fixedArgCount || explicitVariadicArray) {
    return;
  }

  std::vector<ExprPtr> packedArgs;
  packedArgs.reserve(fixedArgCount + 1);
  for (size_t i = 0; i < fixedArgCount; ++i) {
    packedArgs.push_back(expr->arguments[i]);
  }
  std::vector<ExprPtr> restArgs(
      expr->arguments.begin() + static_cast<std::ptrdiff_t>(fixedArgCount),
      expr->arguments.end());
  auto varArray = std::make_shared<ArrayLiteralExprAST>(expr->loc, restArgs);

  TypePtr variadicTarget =
      matchedFn->type && !matchedFn->type->paramTypes.empty()
          ? matchedFn->type->paramTypes.back()->substitute(bindings)
          : nullptr;
  TypePtr elemType = variadicTarget && (variadicTarget->isArray() ||
                                        variadicTarget->isSlice())
                         ? variadicTarget->elementType
                         : variadicTarget;
  if (!elemType) elemType = Type::makeUnknown();

  varArray->inferredType =
      checkArrayLiteralExpr(varArray, Type::makeSlice(elemType));
  packedArgs.push_back(varArray);
  expr->arguments = packedArgs;
}

void TypeChecker::setCallTargetParamTypes(
    std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
    const std::map<std::string, TypePtr>& bindings) {
  expr->targetVariadic =
      matchedFn && matchedFn->funcAST &&
      !matchedFn->funcAST->parameters.empty() &&
      matchedFn->funcAST->parameters.back().isVariadic &&
      !isExternFunction(matchedFn->funcAST.get());
  expr->targetParamTypes =
      matchedFn && matchedFn->type && !matchedFn->type->paramTypes.empty()
          ? matchedFn->type->paramTypes
          : std::vector<TypePtr>{};
  for (auto& paramType : expr->targetParamTypes) {
    paramType = paramType ? paramType->substitute(bindings) : nullptr;
  }
}

void TypeChecker::resolveDeferredPointerArguments(
    std::vector<ExprPtr>& arguments,
    const std::vector<TypePtr>& paramTypes,
    const std::map<std::string, TypePtr>& bindings, const Location& loc) {
  for (size_t i = 0; i < arguments.size() && i < paramTypes.size(); ++i) {
    ExprPtr argument = arguments[i];
    TypePtr argType = argument ? argument->inferredType : nullptr;
    if (!isDeferredStructPointerMatch(argType, paramTypes[i], bindings)) {
      continue;
    }

    auto addressOf = std::dynamic_pointer_cast<UnaryExprAST>(argument);
    const bool isAddressOfValue = addressOf && addressOf->op == "&";
    auto rootIdent = getRootIdentifier(argument);
    if (!rootIdent) continue;

    TypePtr substitutedType = argType->substitute(bindings);
    TypePtr resolvedType = substitutedType ? substitutedType->underlyingType()
                                           : nullptr;
    if (resolvedType && resolvedType->isPointer()) {
      resolvedType = resolvedType->pointerBase
                         ? resolvedType->pointerBase->underlyingType()
                         : nullptr;
    }

    Symbol* variable = m_symbolTable.lookupVar(rootIdent->name);
    if (variable && variable->type &&
        containsGenericParam(variable->type)) {
      TypePtr variableType = variable->type->substitute(bindings);
      if (variableType) {
        *variable->type = *variableType;
        instantiateType(variable->type, loc);
        resolvedType = variable->type;
      }
    }
    if (!resolvedType || containsGenericParam(resolvedType)) continue;

    TypePtr originalType = argType->underlyingType();
    if (originalType && originalType->isPointer() && !isAddressOfValue) {
      if (!std::dynamic_pointer_cast<IdentifierExprAST>(argument)) continue;
      rootIdent->inferredType =
          variable && variable->type ? variable->type : argType;
      argument->inferredType = rootIdent->inferredType;
      continue;
    }

    rootIdent->inferredType = resolvedType;
    if (isAddressOfValue) {
      addressOf->inferredType = Type::makePointer(resolvedType);
    } else {
      auto synthesizedAddress =
          std::make_shared<UnaryExprAST>(argument->loc, "&", argument);
      synthesizedAddress->inferredType = Type::makePointer(resolvedType);
      arguments[i] = synthesizedAddress;
    }
  }
}

void TypeChecker::resolveDeferredVariableParam(ExprPtr expr, TypePtr concreteType) {
  if (!expr || !concreteType || containsGenericParam(concreteType)) return;
  TypePtr argType = expr->inferredType;
  if (!argType) return;
  TypePtr effectiveTarget = argType->underlyingType();
  if (!effectiveTarget || !effectiveTarget->isGenericParam()) return;

  auto rootIdent = getRootIdentifier(expr);
  if (!rootIdent) return;
  Symbol* variable = m_symbolTable.lookupVar(rootIdent->name);
  if (!variable || !variable->type) return;
  TypePtr variableType = variable->type->underlyingType();
  TypePtr genericType = variableType;
  if (genericType && genericType->isPointer()) {
    genericType = genericType->pointerBase
                      ? genericType->pointerBase->underlyingType()
                      : nullptr;
  }
  if (!genericType || (!genericType->isStruct() && !genericType->isUnion())) return;

  const std::vector<std::string>* typeParams = nullptr;
  if (genericType->isStruct()) {
    auto declIt = m_genericStructDecls.find(genericType->name);
    if (declIt != m_genericStructDecls.end()) {
      typeParams = &declIt->second->typeParams;
    }
  } else {
    auto declIt = m_genericUnionDecls.find(genericType->name);
    if (declIt != m_genericUnionDecls.end()) {
      typeParams = &declIt->second->typeParams;
    }
  }
  if (!typeParams) return;
  const auto& params = *typeParams;
  auto paramIt = std::find(params.begin(), params.end(), effectiveTarget->name);
  if (paramIt == params.end()) return;
  const size_t paramIndex = static_cast<size_t>(paramIt - params.begin());
  std::map<std::string, TypePtr> bindings;
  for (size_t i = 0; i < params.size() && i < genericType->typeArgs.size(); ++i) {
    bindings[params[i]] = genericType->typeArgs[i];
  }
  auto bindingIt = bindings.find(effectiveTarget->name);
  if (bindingIt != bindings.end() && bindingIt->second &&
      bindingIt->second->isGenericParam() &&
      paramIndex < genericType->typeArgs.size()) {
    bindingIt->second = concreteType;
    TypePtr resolvedType = variable->type->substitute(bindings);
    *variable->type = *resolvedType;
    instantiateType(variable->type, expr->loc);
    expr->inferredType = argType->substitute(bindings);
  }
}

TypePtr TypeChecker::applyMatchedFunctionCall(
    std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
    const std::map<std::string, TypePtr>& bindings) {
  if (!matchedFn) return Type::makeError();

  if (matchedFn->type && matchedFn->type->isFunction()) {
    for (size_t i = 0;
         i < expr->arguments.size() &&
         i < matchedFn->type->paramTypes.size();
         ++i) {
      inferGenericStructFromExpected(
          expr->arguments[i],
          matchedFn->type->paramTypes[i]->substitute(bindings), expr->loc);
    }
    resolveDeferredPointerArguments(expr->arguments,
                                    matchedFn->type->paramTypes, bindings,
                                    expr->loc);
    for (size_t i = 0; i < expr->arguments.size() && i < matchedFn->type->paramTypes.size(); ++i) {
      TypePtr expectedType =
          matchedFn->type->paramTypes[i]->substitute(bindings);
      resolveDeferredVariableParam(expr->arguments[i], expectedType);
    }
  }

  setMatchedFunctionTarget(expr, matchedFn, bindings);
  packVariadicCallArguments(expr, matchedFn, bindings);
  setCallTargetParamTypes(expr, matchedFn, bindings);
  return resolveMatchedFunctionReturnType(matchedFn, bindings);
}

TypePtr TypeChecker::finalizeUfcsMatchedCall(
    std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
    const std::map<std::string, TypePtr>& bindings,
    const std::vector<ExprPtr>& fullArguments) {
  expr->arguments = fullArguments;
  if (matchedFn && matchedFn->type && matchedFn->type->isFunction()) {
    for (size_t i = 0;
         i < expr->arguments.size() &&
         i < matchedFn->type->paramTypes.size();
         ++i) {
      inferGenericStructFromExpected(
          expr->arguments[i],
          matchedFn->type->paramTypes[i]->substitute(bindings), expr->loc);
    }
    resolveDeferredPointerArguments(expr->arguments,
                                    matchedFn->type->paramTypes, bindings,
                                    expr->loc);
    for (size_t i = 0; i < expr->arguments.size() && i < matchedFn->type->paramTypes.size(); ++i) {
      TypePtr expectedType =
          matchedFn->type->paramTypes[i]->substitute(bindings);
      resolveDeferredVariableParam(expr->arguments[i], expectedType);
    }
  }
  setMatchedFunctionTarget(expr, matchedFn, bindings);
  packVariadicCallArguments(expr, matchedFn, bindings);
  setCallTargetParamTypes(expr, matchedFn, bindings);
  expr->callee =
      std::make_shared<IdentifierExprAST>(expr->loc, matchedFn->name);
  return resolveMatchedFunctionReturnType(matchedFn, bindings);
}

void TypeChecker::reportDirectCallMismatchErrors(
    std::shared_ptr<CallExprAST> expr, Symbol* fnSym,
    const std::string& functionName) {
  auto fType = fnSym ? fnSym->type : nullptr;
  if (!fType || !fType->isFunction()) {
    error(expr->loc, "Invalid call to function '" + functionName + "'");
    return;
  }

  if (expr->arguments.size() != fType->paramTypes.size()) {
    error(expr->loc, "Function '" + functionName + "' expected " +
                         std::to_string(fType->paramTypes.size()) +
                         " arguments, but got " +
                         std::to_string(expr->arguments.size()));
    return;
  }

  std::map<std::string, TypePtr> bindings =
      collectExplicitTemplateBindings(expr, fnSym->funcAST);
  for (size_t i = 0; i < expr->arguments.size(); ++i) {
    TypePtr argT = checkExpression(expr->arguments[i]);
    if (fnSym->funcAST && i < fType->paramTypes.size()) {
      deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
    }
  }

  if (hasUnboundTemplateParams(fnSym->funcAST, bindings)) {
    error(expr->loc, "Could not deduce template arguments for function '" +
                         functionName + "'");
    return;
  }

  for (size_t i = 0; i < expr->arguments.size(); ++i) {
    TypePtr argT = checkExpression(expr->arguments[i]);
    TypePtr expectedP =
        (i < fType->paramTypes.size() && fType->paramTypes[i])
            ? fType->paramTypes[i]->substitute(bindings)
            : nullptr;
    if (!isAssignable(argT, expectedP)) {
      error(expr->loc, "Type mismatch for argument " + std::to_string(i + 1) +
                           " in call to '" + functionName +
                           "': cannot convert '" +
                           (argT ? argT->toString() : "unknown") + "' to '" +
                           expectedP->toString() + "'");
    }
  }
}

void TypeChecker::reportUfcsCallMismatchErrors(
    std::shared_ptr<CallExprAST> expr,
    std::shared_ptr<MemberAccessExprAST> memAccess,
    const std::vector<Symbol*>& funcs) {
  Symbol* fnSym = funcs.empty() ? nullptr : funcs[0];
  auto fType = fnSym ? fnSym->type : nullptr;
  if (!fType || !fType->isFunction()) {
    error(expr->loc, "Invalid arguments for function '" +
                         memAccess->memberName + "'");
    return;
  }

  size_t expectedNumArgs =
      fType->paramTypes.empty() ? 0 : fType->paramTypes.size() - 1;
  if (expr->arguments.size() != expectedNumArgs) {
    error(expr->loc, "Function '" + memAccess->memberName + "' expected " +
                         std::to_string(expectedNumArgs) +
                         " arguments, but got " +
                         std::to_string(expr->arguments.size()));
    return;
  }

  std::map<std::string, TypePtr> bindings =
      collectExplicitTemplateBindings(expr, fnSym->funcAST);
  if (hasUnboundTemplateParams(fnSym->funcAST, bindings)) {
    error(expr->loc, "Could not deduce template arguments for function '" +
                         memAccess->memberName + "'");
  } else {
    error(expr->loc, "Type mismatch in call to function '" +
                         memAccess->memberName + "'");
  }
}

TypePtr TypeChecker::checkUserLiteralCall(std::shared_ptr<CallExprAST> expr,
                                          TypePtr expectedType) {
  const std::string& suffix = expr->literalSuffix;
  std::vector<Symbol*> funcs = m_symbolTable.lookupFunctions(suffix);
  if (funcs.empty()) {
    error(expr->loc, "Undefined user defined literal '" + suffix + "'");
    return Type::makeError();
  }

  bool hasUserLitAttr = false;
  for (Symbol* fnSym : funcs) {
    if (fnSym->funcAST &&
        hasAttribute(fnSym->funcAST->attributes, "user_literal")) {
      hasUserLitAttr = true;
      break;
    }
  }
  if (!hasUserLitAttr) {
    error(expr->loc, "Function '" + suffix +
                         "' used as user defined literal must be annotated "
                         "with [userLiteral]");
    return Type::makeError();
  }

  FunctionOverloadMatch match =
      findBestDirectFunctionOverload(expr, funcs, expectedType);
  if (match.function) {
    expr->callee = std::make_shared<IdentifierExprAST>(expr->loc,
                                                         match.function->name);
    return applyMatchedFunctionCall(expr, match.function, match.bindings);
  }

  reportDirectCallMismatchErrors(expr, funcs[0], suffix);
  return Type::makeError();
}

TypePtr TypeChecker::checkMemberAccessCall(
    std::shared_ptr<CallExprAST> expr,
    std::shared_ptr<MemberAccessExprAST> memAccess, TypePtr expectedType) {
  TypePtr objType = checkExpression(memAccess->object);
  TypePtr rawObjType = objType ? objType->underlyingType() : nullptr;
  if (rawObjType && rawObjType->isPointer() && rawObjType->pointerBase) {
    rawObjType = rawObjType->pointerBase->underlyingType();
  }

  std::string ownerName = rawObjType ? rawObjType->name : "";
  if (!ownerName.empty()) {
    std::vector<Symbol*> staticMethods = m_symbolTable.lookupStaticMethods(
        ownerName, memAccess->memberName);
    if (!staticMethods.empty()) {
      UfcsOverloadMatch match =
          findBestUfcsFunctionOverload(expr, objType, staticMethods, memAccess,
                                       expectedType);
      if (match.function) {
        return finalizeUfcsMatchedCall(expr, match.function, match.bindings,
                                       match.fullArguments);
      }
    }
  }

  std::vector<Symbol*> funcs =
      m_symbolTable.lookupFunctions(memAccess->memberName);
  if (!funcs.empty()) {
    UfcsOverloadMatch match =
        findBestUfcsFunctionOverload(expr, objType, funcs, memAccess,
                                     expectedType);
    if (match.function) {
      return finalizeUfcsMatchedCall(expr, match.function, match.bindings,
                                     match.fullArguments);
    }
    reportUfcsCallMismatchErrors(expr, memAccess, funcs);
    return Type::makeError();
  }

  if (rawObjType && (rawObjType->isStruct() || rawObjType->isUnion())) {
    for (const auto& field : rawObjType->fields) {
      TypePtr fType = field.type ? field.type->underlyingType() : nullptr;
      if (field.name != memAccess->memberName || !fType ||
          (!fType->isFunction() && !fType->isClosure())) {
        continue;
      }
      if (expr->arguments.size() != fType->paramTypes.size()) {
        error(expr->loc, "Function field '" + memAccess->memberName +
                             "' expected " +
                             std::to_string(fType->paramTypes.size()) +
                             " arguments, but got " +
                             std::to_string(expr->arguments.size()));
        return Type::makeError();
      }
      for (size_t i = 0; i < expr->arguments.size(); ++i) {
        TypePtr argT =
            checkExpression(expr->arguments[i], fType->paramTypes[i]);
        if (!isAssignable(argT, fType->paramTypes[i])) {
          error(expr->loc,
                "Type mismatch for argument " + std::to_string(i + 1) +
                    " in call to field '" + memAccess->memberName + "'");
        }
      }
      expr->targetParamTypes = fType->paramTypes;
      return fType->returnType ? fType->returnType
                               : Type::makePrimitive("void");
    }
    return Type::makePrimitive("void");
  }

  error(expr->loc,
        "Unknown function or method '" + memAccess->memberName + "'");
  return Type::makeError();
}

TypePtr TypeChecker::checkIdentifierCall(
    std::shared_ptr<CallExprAST> expr,
    std::shared_ptr<IdentifierExprAST> ident, TypePtr expectedType) {
  std::vector<Symbol*> funcs = m_symbolTable.lookupFunctions(ident->name);

  if (!expr->operatorKind.empty()) {
    std::vector<Symbol*> operatorFunctions;
    for (Symbol* function : funcs) {
      if (function && function->funcAST &&
          hasAttribute(function->funcAST->attributes,
                       expr->operatorKind + "_operator")) {
        operatorFunctions.push_back(function);
      }
    }
    if (m_disallowCustomOperators) {
      const size_t errorCount = m_result.errors.size();
      TypePtr builtInType = Type::makeError();
      if (expr->operatorKind == "infix" && expr->arguments.size() == 2) {
        auto builtInExpr = std::make_shared<BinaryExprAST>(
            expr->loc, ident->name, expr->arguments[0], expr->arguments[1]);
        builtInType = checkBinaryExpr(builtInExpr);
      } else if (expr->operatorKind == "prefix" &&
                 expr->arguments.size() == 1) {
        auto builtInExpr =
            std::make_shared<UnaryExprAST>(expr->loc, ident->name,
                                           expr->arguments[0]);
        builtInType = checkUnaryExpr(builtInExpr);
      } else if (expr->operatorKind == "postfix" &&
                 expr->arguments.size() == 1) {
        auto builtInExpr =
            std::make_shared<PostfixUnaryExprAST>(expr->loc, ident->name,
                                                  expr->arguments[0]);
        builtInType = checkPostfixUnaryExpr(builtInExpr);
      }

      if (builtInType && builtInType->kind != TypeKind::Error) {
        expr->usesBuiltinOperator = true;
        return builtInType;
      }
      if (m_result.errors.size() == errorCount) {
        error(expr->loc,
              "Custom operator '" + ident->name +
                  "' is disabled by [[no_custom_operators]]");
      }
      return Type::makeError();
    }
    funcs = std::move(operatorFunctions);
    if (funcs.empty()) {
      error(expr->loc, "No " + expr->operatorKind + " operator '" +
                           ident->name + "' has been declared");
      return Type::makeError();
    }
  }

  if (funcs.empty()) {
    return checkCallableExprCall(expr);
  }

  FunctionOverloadMatch match =
      findBestDirectFunctionOverload(expr, funcs, expectedType);
  if (match.function) {
    return applyMatchedFunctionCall(expr, match.function, match.bindings);
  }

  reportDirectCallMismatchErrors(expr, funcs[0], ident->name);
  return Type::makeError();
}

TypePtr TypeChecker::checkCallableExprCall(std::shared_ptr<CallExprAST> expr) {
  TypePtr calleeType = checkExpression(expr->callee);
  TypePtr resolvedCallee =
      calleeType ? calleeType->underlyingType() : nullptr;

  if (resolvedCallee &&
      (resolvedCallee->isClosure() || resolvedCallee->isFunction())) {
    if (expr->arguments.size() != resolvedCallee->paramTypes.size()) {
      error(expr->loc, "Callable expected " +
                           std::to_string(resolvedCallee->paramTypes.size()) +
                           " arguments, but got " +
                           std::to_string(expr->arguments.size()));
      return Type::makeError();
    }
    for (size_t i = 0; i < expr->arguments.size(); ++i) {
      TypePtr argT =
          checkExpression(expr->arguments[i], resolvedCallee->paramTypes[i]);
      if (!isAssignable(argT, resolvedCallee->paramTypes[i])) {
        error(expr->loc, "Type mismatch for argument " + std::to_string(i + 1) +
                             " in call: cannot convert '" +
                             (argT ? argT->toString() : "unknown") + "' to '" +
                             resolvedCallee->paramTypes[i]->toString() + "'");
      }
    }
    expr->targetParamTypes = resolvedCallee->paramTypes;
    return resolvedCallee->returnType ? resolvedCallee->returnType
                                      : Type::makePrimitive("void");
  }

  if (!calleeType || calleeType->kind == TypeKind::Error) {
    return Type::makeError();
  }

  error(expr->loc, "Expression is not callable");
  return Type::makeError();
}

TypePtr TypeChecker::checkCallExpr(std::shared_ptr<CallExprAST> expr,
                                   TypePtr expectedType) {
  if (expr->isUserLiteral) {
    return checkUserLiteralCall(expr, expectedType);
  }

  if (auto memAccess =
          std::dynamic_pointer_cast<MemberAccessExprAST>(expr->callee)) {
    return checkMemberAccessCall(expr, memAccess, expectedType);
  }

  if (auto ident = std::dynamic_pointer_cast<IdentifierExprAST>(expr->callee)) {
    return checkIdentifierCall(expr, ident, expectedType);
  }

  return checkCallableExprCall(expr);
}

TypePtr TypeChecker::checkStaticMethodCallExpr(
    std::shared_ptr<StaticMethodCallExprAST> expr,
    TypePtr expectedReturnType) {
  std::string targetType = expr->targetType;
  if (Symbol* targetSym = m_symbolTable.lookupType(targetType);
      targetSym && targetSym->isType && targetSym->type) {
    TypePtr resolvedTarget = targetSym->type->underlyingType();
    if (resolvedTarget &&
        (resolvedTarget->isStruct() || resolvedTarget->isUnion() ||
         resolvedTarget->isEnum() || resolvedTarget->isPrimitive())) {
      targetType = resolvedTarget->name;
    }
  }

  std::vector<Symbol*> smSyms =
      m_symbolTable.lookupStaticMethods(targetType, expr->methodName);
  if (smSyms.empty()) {
    error(expr->loc, "Static method '" + expr->targetType +
                         "::" + expr->methodName + "' not found");
    return Type::makeError();
  }

  Symbol* bestSm = nullptr;
  std::map<std::string, TypePtr> bestBindings;
  int maxScore = -1;

  for (Symbol* smSym : smSyms) {
    if (!smSym->type || !smSym->type->isFunction()) continue;
    auto fType = smSym->type;
    if (expr->arguments.size() != fType->paramTypes.size()) continue;

    std::map<std::string, TypePtr> bindings;
    if (smSym->funcAST && !expr->templateArgs.empty()) {
      for (size_t i = 0; i < expr->templateArgs.size() &&
                         i < smSym->funcAST->typeParams.size();
           ++i) {
        const auto& typeParam = smSym->funcAST->typeParams[i];
        bindings[typeParam] = resolveTypeAST(expr->templateArgs[i]);
      }
    }

    bool valid = true;
    int score = 0;
    for (size_t i = 0; i < expr->arguments.size(); ++i) {
      TypePtr argT = checkExpression(expr->arguments[i]);
      if (smSym->funcAST && i < fType->paramTypes.size())
        deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
    }

    if (!deduceTemplateArgsFromExpectedReturn(
            smSym->funcAST, fType->returnType, expectedReturnType, bindings)) {
      valid = false;
    }

    for (size_t i = 0; i < expr->arguments.size(); ++i) {
      TypePtr argT = expr->arguments[i]->inferredType;
      TypePtr expectedP = (i < fType->paramTypes.size() && fType->paramTypes[i])
                              ? fType->paramTypes[i]->substitute(bindings)
                              : nullptr;
      if (!isAssignable(argT, expectedP)) {
        valid = false;
        break;
      }
      score += (argT && expectedP && argT->equals(expectedP)) ? 2 : 1;
    }

    if (smSym->funcAST) {
      for (const auto& tp : smSym->funcAST->typeParams) {
        if (bindings.find(tp) == bindings.end() || !bindings.at(tp) ||
            bindings.at(tp)->isUnknown()) {
          valid = false;
          break;
        }
      }
    }

    if (valid && score > maxScore) {
      maxScore = score;
      bestSm = smSym;
      bestBindings = bindings;
    }
  }

  if (bestSm) {
    if (bestSm->type && bestSm->type->isFunction()) {
      for (size_t i = 0;
           i < expr->arguments.size() &&
           i < bestSm->type->paramTypes.size();
           ++i) {
        inferGenericStructFromExpected(
            expr->arguments[i],
            bestSm->type->paramTypes[i]->substitute(bestBindings),
            expr->loc);
      }
    }
    if (!bestSm->mangledName.empty()) {
      expr->targetMangledName = bestSm->mangledName;
    }
    if (bestSm->funcAST) {
      std::string instMangled =
          instantiateFunction(bestSm->funcAST, bestBindings, expr->loc);
      if (!instMangled.empty()) {
        expr->targetMangledName = instMangled;
      }
    }

    expr->targetParamTypes = bestSm->type && !bestSm->type->paramTypes.empty()
                                 ? bestSm->type->paramTypes
                                 : std::vector<TypePtr>{};
    for (auto& p : expr->targetParamTypes) {
      p = p ? p->substitute(bestBindings) : nullptr;
    }
    {
      TypePtr ret = nullptr;
      if (bestSm->funcAST) {
        m_symbolTable.enterScope();
        for (const auto& tp : bestSm->funcAST->typeParams) {
          auto it = bestBindings.find(tp);
          if (it != bestBindings.end() && it->second)
            m_symbolTable.defineType(tp, it->second);
          else
            m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
        }
        ret = bestSm->funcAST->returnTypeAst
                  ? resolveTypeAST(bestSm->funcAST->returnTypeAst)
                  : Type::makePrimitive("void");
        m_symbolTable.exitScope();
      } else {
        ret = bestSm->type && bestSm->type->returnType
                  ? bestSm->type->returnType->substitute(bestBindings)
                  : Type::makePrimitive("void");
      }
      expr->targetReturnType = ret ? ret : Type::makePrimitive("void");
    }

    Symbol* typeSym = m_symbolTable.lookupType(targetType);
    if (typeSym && typeSym->type && typeSym->type->isStruct() &&
        !typeSym->type->typeArgs.empty()) {
      std::vector<TypePtr> tArgs;
      for (const auto& ta : expr->templateArgs)
        tArgs.push_back(resolveTypeAST(ta));
      auto structType = Type::makeStruct(targetType, tArgs);
      instantiateType(structType, expr->loc);
    }

    return expr->targetReturnType;
  }

  Symbol* smSym = smSyms[0];
  auto fType = smSym ? smSym->type : nullptr;
  if (fType && fType->isFunction()) {
    if (expr->arguments.size() != fType->paramTypes.size()) {
      error(expr->loc, "Static method '" + expr->targetType +
                           "::" + expr->methodName + "' expected " +
                           std::to_string(fType->paramTypes.size()) +
                           " arguments, but got " +
                           std::to_string(expr->arguments.size()));
    } else {
      error(expr->loc, "Type mismatch in call to static method '" +
                           expr->targetType + "::" + expr->methodName + "'");
    }
  }
  return Type::makeError();
}

TypePtr TypeChecker::checkMemberAccessExpr(std::shared_ptr<MemberAccessExprAST> expr) {
  TypePtr objType = checkExpression(expr->object);

  if (objType) {
    objType = objType->underlyingType();
  }

  const bool isList = objType && objType->typeArgs.size() == 1 &&
                      (isCoreListType(objType) || isStdListType(objType));

  if (objType && objType->isPointer()) {
    objType = objType->pointerBase;
    if (objType) {
      objType = objType->underlyingType();
    }

    if (objType && (objType->name == "char" || objType->name == "uchar")) {
        objType = Type::makeSlice(objType);
    }
  }

  if (!isList && isCoreManagedType(objType) &&
      objType->typeArgs.size() == 1) {
    objType = objType->typeArgs.front()->underlyingType();
  }

  if (objType && objType->isStruct()) {
    auto genericDecl = m_genericStructDecls.find(objType->name);
    if (genericDecl != m_genericStructDecls.end() &&
        objType->typeArgs.size() == genericDecl->second->typeParams.size()) {
      m_symbolTable.enterScope();
      for (size_t i = 0; i < objType->typeArgs.size(); ++i) {
        m_symbolTable.defineType(genericDecl->second->typeParams[i],
                                 objType->typeArgs[i]);
      }
      for (const auto& alias : genericDecl->second->typeAliases) {
        if (alias) {
          m_symbolTable.defineTypeAlias(alias->aliasName, alias);
        }
      }
      for (const auto& field : genericDecl->second->fields) {
        if (field.name == expr->memberName) {
          TypePtr fieldType = resolveTypeAST(field.typeAst);
          m_symbolTable.exitScope();
          expr->inferredType = fieldType;
          return fieldType;
        }
      }
      m_symbolTable.exitScope();
    }
  }

  if (objType && (objType->isStruct() || objType->isUnion())) {
    for (const auto& f : objType->fields) {
      if (f.name == expr->memberName) {
        return f.type;
      }
    }
  }

  if (isList && expr->memberName == "length") {
    return Type::makePrimitive("int");
  }

  if (objType && (objType->isArray() || objType->isSlice())) {
    if (expr->memberName == "length") {
      return Type::makePrimitive("int");
    }
    error(expr->loc, "Unknown member '" + expr->memberName + "' on type '" +
                         objType->toString() +
                         "'. Arrays and slices only have a 'length' property.");
    return Type::makeError();
  }

  if (objType && objType->isTuple()) {
    try {
      size_t idx = std::stoul(expr->memberName);
      if (idx < objType->tupleElementTypes.size()) {
        return objType->tupleElementTypes[idx];
      }
    } catch (...) {
      error(expr->loc, "Unknown member '" + expr->memberName + "' on type '" +
                   (objType ? objType->toString() : "unknown") + "', tuples are indexed using interger constants, starting from 0");
    }
  }

  error(expr->loc, "Unknown member '" + expr->memberName + "' on type '" +
                       (objType ? objType->toString() : "unknown") + "'");
  return Type::makeError();
}

TypePtr TypeChecker::checkStructInitExpr(
    std::shared_ptr<StructInitExprAST> expr, TypePtr expectedType) {
  TypePtr stType = resolveTypeAST(expr->structType);
  auto findFieldIndex = [&](const std::string& fieldName,
                            const TypePtr& targetType) {
    if (fieldName.rfind("_pos_", 0) == 0) {
      return static_cast<size_t>(std::stoul(fieldName.substr(5)));
    }
    TypePtr normalizedType =
        targetType ? targetType->underlyingType() : nullptr;
    if (normalizedType &&
        (normalizedType->isStruct() || normalizedType->isUnion())) {
      for (size_t i = 0; i < normalizedType->fields.size(); ++i) {
        if (normalizedType->fields[i].name == fieldName) return i;
      }
    }
    return static_cast<size_t>(-1);
  };

  if (expr->structType && m_genericStructDecls.count(expr->structType->name)) {
    auto templateDecl = m_genericStructDecls[expr->structType->name];
    std::map<std::string, TypePtr> bindings;
    std::map<std::string, TypePtr> explicitBindings;

    if (!expr->structType->templateArgs.empty()) {
      for (size_t i = 0; i < expr->structType->templateArgs.size() &&
                         i < templateDecl->typeParams.size();
           ++i) {
        explicitBindings[templateDecl->typeParams[i]] =
            resolveTypeAST(expr->structType->templateArgs[i]);
        bindings[templateDecl->typeParams[i]] =
            explicitBindings[templateDecl->typeParams[i]];
      }
    }

    TypePtr expectedStructType =
        expectedType ? expectedType->underlyingType() : nullptr;
    if (expectedStructType && expectedStructType->isStruct() &&
        expectedStructType->name == templateDecl->name &&
        expectedStructType->typeArgs.size() == templateDecl->typeParams.size()) {
      for (size_t i = 0; i < templateDecl->typeParams.size(); ++i) {
        const auto& typeParam = templateDecl->typeParams[i];
        if (bindings.find(typeParam) == bindings.end()) {
          bindings[typeParam] = expectedStructType->typeArgs[i];
        }
      }
    }

    for (size_t i = 0; i < expr->fieldInits.size(); ++i) {
      const auto& init = expr->fieldInits[i];

      std::string fieldName = init.first;
      TypeASTPtr fieldTypeAST = nullptr;

      if (fieldName.rfind("_pos_", 0) == 0) {
        size_t posIdx = std::stoul(fieldName.substr(5));
        if (posIdx < templateDecl->fields.size()) {
          fieldTypeAST = templateDecl->fields[posIdx].typeAst;
        }
      } else {
        for (const auto& f : templateDecl->fields) {
          if (f.name == fieldName) {
            fieldTypeAST = f.typeAst;
            break;
          }
        }
      }

      if (fieldTypeAST) {
        m_symbolTable.enterScope();
        for (const auto& tp : templateDecl->typeParams) {
          auto binding = bindings.find(tp);
          m_symbolTable.defineType(
              tp, binding != bindings.end() && binding->second
                      ? binding->second
                      : Type::makeGenericParam(tp));
        }
        for (const auto& alias : templateDecl->typeAliases) {
          if (alias) {
            m_symbolTable.defineTypeAlias(alias->aliasName, alias);
          }
        }
        TypePtr declFType = resolveTypeAST(fieldTypeAST);
        m_symbolTable.exitScope();
        TypePtr valType =
            init.second ? checkExpression(init.second, declFType) : nullptr;
        if (declFType && valType) {
          deduceTemplateArgs(declFType, valType, bindings);
        }
      } else if (init.second) {
        checkExpression(init.second);
      }
    }

    std::vector<TypePtr> tArgs;
    for (const auto& tp : templateDecl->typeParams) {
      auto inferred = bindings.find(tp);
      auto explicitType = explicitBindings.find(tp);
      if (explicitType != explicitBindings.end() && inferred != bindings.end() &&
          inferred->second && !containsGenericParam(inferred->second) &&
          !explicitType->second->equals(inferred->second)) {
        error(expr->loc, "Cannot infer generic parameter '" + tp +
                             "' for '" + templateDecl->name +
                             "': initializer field has type '" +
                             inferred->second->toString() +
                             "', but the explicit type is '" +
                             explicitType->second->toString() + "'");
      }
      if (inferred != bindings.end() && inferred->second &&
          !inferred->second->isUnknown()) {
        tArgs.push_back(inferred->second);
      } else {
        tArgs.push_back(Type::makeGenericParam(tp));
      }
    }

    if (tArgs.size() != templateDecl->typeParams.size() &&
        m_currentReturnType && m_currentReturnType->name == expr->structType->name &&
        m_currentReturnType->typeArgs.size() == templateDecl->typeParams.size()) {
      tArgs = m_currentReturnType->typeArgs;
    }

    if (tArgs.size() == templateDecl->typeParams.size()) {
      stType = Type::makeStruct(expr->structType->name, tArgs);
      if (!containsGenericParam(stType)) {
        instantiateType(stType, expr->loc);
        expr->structType = makeTypeASTFromType(stType, expr->loc);
      }
    }

    if (stType && stType->isStruct()) {
      for (auto& fieldInit : expr->fieldInits) {
        size_t index = findFieldIndex(fieldInit.first, stType);
        if (index >= stType->fields.size()) continue;
        TypePtr targetFType = stType->fields[index].type;
        ExprPtr valExpr = fieldInit.second;
        if (targetFType && targetFType->isPointer() && valExpr &&
            valExpr->inferredType && !valExpr->inferredType->isPointer() &&
            !valExpr->inferredType->isArray() &&
            !valExpr->inferredType->isSlice()) {
          auto addrOf = std::make_shared<UnaryExprAST>(valExpr->loc, "&", valExpr);
          addrOf->inferredType = Type::makePointer(valExpr->inferredType);
          fieldInit.second = addrOf;
        }
      }
    }
  } else {
    for (auto& fieldInit : expr->fieldInits) {
      TypePtr normalizedType = stType ? stType->underlyingType() : nullptr;
      size_t index = findFieldIndex(fieldInit.first, normalizedType);
      TypePtr targetFieldType =
          normalizedType && index < normalizedType->fields.size()
              ? normalizedType->fields[index].type
              : nullptr;
      if (fieldInit.second) {
        if (auto arrayLiteral =
                std::dynamic_pointer_cast<ArrayLiteralExprAST>(
                    fieldInit.second)) {
          checkArrayLiteralExpr(arrayLiteral, targetFieldType);
        } else {
          checkExpression(fieldInit.second);
        }
      }
      if (!normalizedType || !normalizedType->isStruct() ||
          index >= normalizedType->fields.size()) {
        continue;
      }
      ExprPtr value = fieldInit.second;
      if (targetFieldType && targetFieldType->isPointer() && value &&
          value->inferredType && !value->inferredType->isPointer() &&
          !value->inferredType->isArray() &&
          !value->inferredType->isSlice()) {
        auto addressOf =
            std::make_shared<UnaryExprAST>(value->loc, "&", value);
        addressOf->inferredType = Type::makePointer(value->inferredType);
        fieldInit.second = addressOf;
      }
    }
  }

  TypePtr normalizedType = stType ? stType->underlyingType() : nullptr;
  if (normalizedType &&
      (normalizedType->isStruct() || normalizedType->isUnion())) {
    std::vector<bool> initializedFields(normalizedType->fields.size(), false);
    if (normalizedType->isUnion() && expr->fieldInits.size() > 1) {
      error(expr->loc, "A union initializer can initialize only one field");
    }
    for (const auto& fieldInit : expr->fieldInits) {
      size_t index = findFieldIndex(fieldInit.first, normalizedType);
      if (index >= normalizedType->fields.size()) {
        error(expr->loc, "Unknown field '" + fieldInit.first +
                             "' in initializer for '" +
                             normalizedType->name + "'");
        continue;
      }
      if (initializedFields[index]) {
        error(expr->loc, "Field '" + normalizedType->fields[index].name +
                             "' is initialized more than once");
        continue;
      }
      initializedFields[index] = true;
      TypePtr valueType =
          fieldInit.second ? fieldInit.second->inferredType : nullptr;
      TypePtr fieldType = normalizedType->fields[index].type;
      if (valueType && valueType->kind != TypeKind::Error && fieldType &&
          !isAssignable(valueType, fieldType)) {
        error(fieldInit.second->loc,
              "Cannot initialize field '" + normalizedType->fields[index].name +
                  "' of type '" + fieldType->toString() + "' with '" +
                  valueType->toString() + "'");
      }
    }
  }

  expr->inferredType = stType;
  return stType;
}

TypePtr TypeChecker::checkIfExpr(std::shared_ptr<IfExprAST> expr,
                                 TypePtr expectedType) {
  TypePtr condType = checkExpression(expr->condition);
  TypePtr thenType = checkExpression(expr->thenBranch, expectedType);
  TypePtr elseType = expr->elseBranch ? checkExpression(expr->elseBranch, expectedType)
                                      : Type::makePrimitive("void");

  if (expectedType && thenType && !isAssignable(thenType, expectedType)) {
    error(expr->thenBranch->loc,
          "If-expression branch has type '" + thenType->toString() +
              "', expected '" + expectedType->toString() + "'");
  }
  if (expr->elseBranch && expectedType && elseType &&
      !isAssignable(elseType, expectedType)) {
    error(expr->elseBranch->loc,
          "If-expression branch has type '" + elseType->toString() +
              "', expected '" + expectedType->toString() + "'");
  }

  if (thenType->equals(elseType)) return thenType;
  return thenType;
}

TypePtr TypeChecker::checkSwitchExpr(std::shared_ptr<SwitchExprAST> expr,
                                     TypePtr expectedType) {
  TypePtr targetType = checkExpression(expr->targetExpr);
  TypePtr resType = nullptr;

  size_t caseIndex = 0;
  for (const auto& c : expr->cases) {
    ++caseIndex;
    if (c.pattern) {
      TypePtr patternType = checkExpression(c.pattern);
      if (c.rangeEnd) {
        TypePtr rangeEndType = checkExpression(c.rangeEnd);
        if (!isNumericPrimitive(targetType)) {
          error(c.pattern->loc,
                "Switch range case " + std::to_string(caseIndex) +
                    " requires a numeric target, but the target has type '" +
                    (targetType ? targetType->toString() : "unknown") + "'");
        } else if (!isAssignable(patternType, targetType) ||
                   !isAssignable(rangeEndType, targetType)) {
          error(c.pattern->loc,
                "Switch range bounds '" +
                    (patternType ? patternType->toString() : "unknown") +
                    "' and '" +
                    (rangeEndType ? rangeEndType->toString() : "unknown") +
                    "' are not compatible with target type '" +
                    targetType->toString() + "'");
        }
      } else if (targetType && patternType &&
                 !isAssignable(patternType, targetType)) {
        error(c.pattern->loc,
              "Switch case " + std::to_string(caseIndex) +
                  " pattern has type '" + patternType->toString() +
                  "', which is not compatible with target type '" +
                  targetType->toString() + "'");
      }
    }
    if (c.body) {
      TypePtr bodyType = checkExpression(c.body, expectedType);
      if (expectedType) {
        if (!isAssignable(bodyType, expectedType)) {
          error(c.body->loc,
                "Switch-expression branch " + std::to_string(caseIndex) +
                    " has type '" +
                    (bodyType ? bodyType->toString() : "unknown") +
                    "', expected '" + expectedType->toString() + "'");
        } else if (!resType) {
          resType = expectedType;
        }
      } else if (bodyType) {
        if (!resType) {
          resType = bodyType;
        } else if (!bodyType->equals(resType)) {
          if (isAssignable(bodyType, resType)) {
            // Narrower branch value, keep the wider inferred type.
          } else if (isAssignable(resType, bodyType)) {
            resType = bodyType;
          } else {
            error(c.body->loc,
                  "Switch-expression branch " + std::to_string(caseIndex) +
                      " has type '" + bodyType->toString() +
                      "', which is incompatible with earlier branch type '" +
                      resType->toString() + "'");
          }
        }
      }
    }
  }

  if (!resType) resType = Type::makePrimitive("int");
  expr->inferredType = resType;
  return resType;
}

TypePtr TypeChecker::checkBlockExpr(std::shared_ptr<BlockExprAST> expr,
                                    TypePtr expectedType) {
  m_symbolTable.enterScope();

  TypePtr previousYieldType = m_currentYieldType;
  TypePtr previousExpectedYieldType = m_expectedYieldType;
  m_currentYieldType.reset();
  m_expectedYieldType = expectedType;
  for (const auto& stmt : expr->statements) {
    checkStatement(stmt);
  }

  TypePtr blockType = Type::makePrimitive("void");

  if (expr->yieldExpr) {  // TODO: Report an error if
    blockType = checkExpression(expr->yieldExpr, expectedType);
  } else if (m_currentYieldType) {
    blockType = m_currentYieldType;
  }

  for (const auto& entry : m_symbolTable.currentScope()->symbols()) {
    const Symbol& symbol = entry.second;
    if (!symbol.isType && !symbol.isFunction &&
        containsGenericParam(symbol.type)) {
      error(expr->loc, "Cannot infer all generic type parameters for variable '" +
                           symbol.name + "' before the end of the block");
    }
  }

  m_currentYieldType = previousYieldType;
  m_expectedYieldType = previousExpectedYieldType;
  m_symbolTable.exitScope();
  return blockType;
}

TypePtr TypeChecker::checkClosureExpr(std::shared_ptr<ClosureExprAST> expr) {
  m_symbolTable.enterClosureScope();

  std::vector<TypePtr> pTypes;
  for (auto& p : expr->params) {
    TypePtr pT =
        p.typeAst ? resolveTypeAST(p.typeAst) : Type::makePrimitive("int");
    if (p.typeAst && pT && pT->kind != TypeKind::Error) {
      p.typeAst = makeTypeASTFromType(pT, p.typeAst->loc);
    }
    pTypes.push_back(pT);
    m_symbolTable.defineVar(p.name, pT, false);
  }

  TypePtr oldRet = m_currentReturnType;
  bool oldHasReturn = m_hasReturnStmt;
  m_hasReturnStmt = false;
  m_currentReturnType =
      expr->returnTypeAst ? resolveTypeAST(expr->returnTypeAst) : nullptr;

  TypePtr bodyType = checkExpression(expr->body);
  TypePtr retType = m_currentReturnType ? m_currentReturnType : bodyType;
  if (!retType) retType = Type::makePrimitive("void");

  if (expr->returnTypeAst && !isAssignable(bodyType, retType)) {
    error(expr->loc, "Return type mismatch in closure: cannot convert '" +
                         bodyType->toString() + "' to '" + retType->toString() +
                         "'");
  }

  m_hasReturnStmt = oldHasReturn;
  m_currentReturnType = oldRet;
  m_symbolTable.exitScope();
  return Type::makeClosure(pTypes, retType);
}

TypePtr TypeChecker::checkAssignExpr(std::shared_ptr<AssignExprAST> expr) {
  TypePtr targetType = checkExpression(expr->target);
  TypePtr valType = checkExpression(expr->value, targetType);

  if (targetType && valType) {
    inferGenericStructFromAssignment(expr->target, valType, expr->loc);
    if (expr->target->inferredType) {
      targetType = expr->target->inferredType;
    }
    resolveDeferredVariableParam(expr->target, valType);
    if (expr->target->inferredType) targetType = expr->target->inferredType;
    TypePtr effectiveTarget = targetType->underlyingType();
    if (effectiveTarget && effectiveTarget->isGenericParam()) {
      if (auto rootIdent = getRootIdentifier(expr->target)) {
        Symbol* variable = m_symbolTable.lookupVar(rootIdent->name);
        TypePtr variableType =
            variable && variable->type ? variable->type->underlyingType()
                                       : nullptr;
        TypePtr genericType = variableType;
        if (genericType && genericType->isPointer()) {
          genericType = genericType->pointerBase
                            ? genericType->pointerBase->underlyingType()
                            : nullptr;
        }
        if (genericType &&
            (genericType->isStruct() || genericType->isUnion())) {
          const std::vector<std::string>* typeParams = nullptr;
          if (genericType->isStruct()) {
            auto declIt = m_genericStructDecls.find(genericType->name);
            if (declIt != m_genericStructDecls.end()) {
              typeParams = &declIt->second->typeParams;
            }
          } else {
            auto declIt = m_genericUnionDecls.find(genericType->name);
            if (declIt != m_genericUnionDecls.end()) {
              typeParams = &declIt->second->typeParams;
            }
          }
          if (typeParams) {
            const auto& params = *typeParams;
            auto paramIt =
                std::find(params.begin(), params.end(),
                          effectiveTarget->name);
            if (paramIt != params.end()) {
              const size_t paramIndex =
                  static_cast<size_t>(paramIt - params.begin());
              std::map<std::string, TypePtr> bindings;
              for (size_t i = 0;
                   i < params.size() && i < genericType->typeArgs.size();
                   ++i) {
                bindings[params[i]] = genericType->typeArgs[i];
              }
              auto bindingIt = bindings.find(effectiveTarget->name);
              if (bindingIt != bindings.end() &&
                  bindingIt->second &&
                  bindingIt->second->isGenericParam() &&
                  paramIndex < genericType->typeArgs.size()) {
                bindingIt->second = valType;
                TypePtr resolvedType = variable->type->substitute(bindings);
                *variable->type = *resolvedType;
                instantiateType(variable->type, expr->loc);
                expr->target->inferredType =
                    targetType->substitute(bindings);
                targetType = expr->target->inferredType;
              }
            }
          }
        }
      }
    }
  }

  if (auto ident = std::dynamic_pointer_cast<IdentifierExprAST>(expr->target)) {
    Symbol* sym = m_symbolTable.lookupVar(ident->name);
    if (sym && sym->isConst) {
      error(expr->loc, "Cannot assign to const variable '" + ident->name + "'");
    }
  }

  if (auto mapIndex = std::dynamic_pointer_cast<IndexExprAST>(expr->target)) {
    TypePtr mapType =
        mapIndex->target && mapIndex->target->inferredType
            ? mapIndex->target->inferredType->underlyingType()
            : nullptr;
    if (mapType && mapType->isHashMap()) {
      targetType = mapType->elementType;
    }
  }

  const bool assignsCorePointerNull =
      std::dynamic_pointer_cast<NullLiteralExprAST>(expr->value) &&
      isCoreManagedType(targetType);
  if (targetType && valType && !isAssignable(valType, targetType) &&
      !assignsCorePointerNull) {
    error(expr->loc, "Cannot assign value of type '" + valType->toString() +
                         "' to target of type '" + targetType->toString() +
                         "'");
  }

  if (expr->op != "=") {
    const std::string binaryOperator =
        expr->op.substr(0, expr->op.size() - 1);
    TypePtr operationType =
        checkBinaryOperation(binaryOperator, targetType, valType, expr->loc);
    if (operationType && operationType->kind != TypeKind::Error &&
        !isAssignable(operationType, targetType)) {
      error(expr->loc, "Cannot assign result of type '" +
                           operationType->toString() +
                           "' to target of type '" + targetType->toString() +
                           "'");
    }
  }

  return targetType;
}

bool TypeChecker::inferGenericStructFromAssignment(
    ExprPtr target, TypePtr valueType, const Location& loc) {
  auto member = std::dynamic_pointer_cast<MemberAccessExprAST>(target);
  IdentifierExprAST* root = getRootIdentifier(target);
  if (!member || !root || !valueType) return false;

  Symbol* variable = m_symbolTable.lookupVar(root->name);
  TypePtr instance =
      variable && variable->type && variable->type->isStruct()
          ? variable->type
          : (variable && variable->type ? variable->type->underlyingType()
                                        : nullptr);
  if (!instance || !instance->isStruct() ||
      instance->typeArgs.empty()) {
    return false;
  }
  auto declaration = m_genericStructDecls.find(instance->name);
  if (declaration == m_genericStructDecls.end()) return false;
  const auto& genericDecl = declaration->second;
  if (genericDecl->typeParams.size() != instance->typeArgs.size()) {
    return false;
  }

  TypeASTPtr fieldTypeAst;
  for (const auto& field : genericDecl->fields) {
    if (field.name == member->memberName) {
      fieldTypeAst = field.typeAst;
      break;
    }
  }
  if (!fieldTypeAst) return false;

  std::map<std::string, TypePtr> bindings;
  m_symbolTable.enterScope();
  for (size_t i = 0; i < genericDecl->typeParams.size(); ++i) {
    bindings[genericDecl->typeParams[i]] = instance->typeArgs[i];
    m_symbolTable.defineType(genericDecl->typeParams[i],
                             instance->typeArgs[i]);
  }
  for (const auto& alias : genericDecl->typeAliases) {
    if (alias) {
      m_symbolTable.defineTypeAlias(alias->aliasName, alias);
    }
  }
  TypePtr declaredFieldType = resolveTypeAST(fieldTypeAst);
  m_symbolTable.exitScope();
  if (!declaredFieldType ||
      !deduceTemplateArgs(declaredFieldType, valueType, bindings)) {
    return false;
  }

  for (size_t i = 0; i < genericDecl->typeParams.size(); ++i) {
    const auto& name = genericDecl->typeParams[i];
    TypePtr previous = instance->typeArgs[i];
    auto inferred = bindings.find(name);
    if (inferred == bindings.end() || !inferred->second) continue;
    if (previous && !previous->isGenericParam() &&
        !previous->equals(inferred->second)) {
      error(loc, "Conflicting inference for generic parameter '" + name +
                     "' in '" + instance->name + "'");
      return false;
    }
  }

  std::vector<TypePtr> resolvedArgs;
  resolvedArgs.reserve(instance->typeArgs.size());
  for (const auto& arg : instance->typeArgs) {
    resolvedArgs.push_back(arg ? arg->substitute(bindings) : nullptr);
  }
  instance->typeArgs = std::move(resolvedArgs);

  if (!containsGenericParam(instance)) {
    instantiateType(instance, loc);
  }
  member->inferredType = declaredFieldType->substitute(bindings);
  target->inferredType = member->inferredType;
  return true;
}

bool TypeChecker::inferGenericStructFromExpected(
    ExprPtr value, TypePtr expectedType, const Location& loc) {
  if (auto initializer =
          std::dynamic_pointer_cast<StructInitExprAST>(value)) {
    TypePtr sourceType = resolveTypeAST(initializer->structType);
    TypePtr targetType = expectedType ? expectedType->underlyingType() : nullptr;
    if (sourceType && targetType && sourceType->isStruct() &&
        targetType->isStruct() && sourceType->name == targetType->name &&
        sourceType->typeArgs.size() == targetType->typeArgs.size() &&
        !targetType->typeArgs.empty() && !containsGenericParam(targetType) &&
        m_genericStructDecls.find(sourceType->name) !=
            m_genericStructDecls.end()) {
      initializer->structType = makeTypeASTFromType(targetType, loc);
      checkStructInitExpr(initializer);
      return true;
    }
  }

  IdentifierExprAST* root = getRootIdentifier(value);
  if (!root || !expectedType) return false;
  Symbol* variable = m_symbolTable.lookupVar(root->name);
  if (!variable || !variable->type) return false;

  TypePtr sourceType = variable->type;
  if (sourceType->isPointer()) sourceType = sourceType->pointerBase;
  if (!sourceType || !sourceType->isStruct() ||
      sourceType->typeArgs.empty()) {
    return false;
  }
  auto declaration = m_genericStructDecls.find(sourceType->name);
  if (declaration == m_genericStructDecls.end() ||
      declaration->second->typeParams.size() != sourceType->typeArgs.size()) {
    return false;
  }

  TypePtr targetType = expectedType->underlyingType();
  if (targetType && targetType->isPointer()) {
    targetType = targetType->pointerBase
                     ? targetType->pointerBase->underlyingType()
                     : nullptr;
  }
  if (!targetType || !targetType->isStruct() ||
      targetType->name != sourceType->name ||
      targetType->typeArgs.size() != sourceType->typeArgs.size() ||
      containsGenericParam(targetType)) {
    return false;
  }

  std::map<std::string, TypePtr> bindings;
  if (!deduceTemplateArgs(sourceType, targetType, bindings)) return false;
  for (size_t i = 0; i < sourceType->typeArgs.size(); ++i) {
    TypePtr previous = sourceType->typeArgs[i];
    auto inferred = bindings.find(declaration->second->typeParams[i]);
    if (previous && !previous->isGenericParam() &&
        !previous->equals(targetType->typeArgs[i])) {
      error(loc, "Cannot pass '" + sourceType->toString() +
                     "' where '" + targetType->toString() +
                     "' is expected");
      return false;
    }
    if (inferred != bindings.end() && inferred->second) {
      sourceType->typeArgs[i] = inferred->second;
    }
  }

  if (!containsGenericParam(sourceType)) {
    instantiateType(sourceType, loc);
  }
  root->inferredType = variable->type;
  if (auto address = std::dynamic_pointer_cast<UnaryExprAST>(value);
      address && address->op == "&") {
    address->inferredType = Type::makePointer(sourceType);
  } else {
    value->inferredType = variable->type;
  }
  return true;
}

TypePtr TypeChecker::checkCastExpr(std::shared_ptr<CastExprAST> expr) {
  TypePtr sourceType = checkExpression(expr->expr);
  TypePtr targetType = resolveTypeAST(expr->targetTypeAst);
  if (targetType && targetType->kind != TypeKind::Error) {
    expr->targetTypeAst = makeTypeASTFromType(targetType, expr->loc);
  }
  if (sourceType && sourceType->isPointer() &&
      isCoreManagedType(targetType)) {
    instantiateType(targetType, expr->loc);
  }
  expr->inferredType = targetType;
  return targetType;
}

TypePtr TypeChecker::checkTupleLiteralExpr(
    std::shared_ptr<TupleLiteralExprAST> expr, TypePtr expectedType) {
  std::vector<TypePtr> elemTypes;
  for (size_t i = 0; i < expr->elements.size(); ++i) {
    TypePtr expectedElement =
        expectedType && expectedType->isTuple() &&
                i < expectedType->tupleElementTypes.size()
            ? expectedType->tupleElementTypes[i]
            : nullptr;
    elemTypes.push_back(checkExpression(expr->elements[i], expectedElement));
  }
  return Type::makeTuple(elemTypes);
}

TypePtr TypeChecker::checkNullLiteralExpr(std::shared_ptr<NullLiteralExprAST> expr) {
  TypePtr nullType = Type::makePointer(Type::makePrimitive("void"));
  expr->inferredType = nullType;
  return nullType;
}

TypePtr TypeChecker::checkArrayLiteralExpr(std::shared_ptr<ArrayLiteralExprAST> expr, TypePtr expectedType) {
  const bool hasExpectedContainer =
      expectedType && (expectedType->isArray() || expectedType->isSlice());
  TypePtr expectedElemType =
      hasExpectedContainer ? expectedType->elementType : nullptr;
  if (expectedElemType && expectedElemType->isUnknown()) {
    expectedElemType.reset();
  }

  if (expr->elements.empty()) {
    if (hasExpectedContainer && expectedElemType) {
      expr->inferredType = expectedType;
      return expectedType;
    }
    TypePtr unknownSlice = Type::makeSlice(Type::makeUnknown());
    expr->inferredType = unknownSlice;
    return unknownSlice;
  }

  if (isVoidPointerType(expectedElemType)) {
    for (const auto& element : expr->elements) {
      TypePtr elemType = checkExpression(element);
      if (!isVariadicArgAssignable(elemType, expectedElemType)) {
        error(expr->loc,
              "Type mismatch in array literal element: cannot convert '" +
                  (elemType ? elemType->toString() : "unknown") + "' to '" +
                  expectedElemType->toString() + "'");
      }
    }
    expr->inferredType = expectedType;
    return expectedType;
  }

  TypePtr inferredElemType = expectedElemType;

  for (size_t i = 0; i < expr->elements.size(); ++i) {
    TypePtr t = checkExpression(expr->elements[i], inferredElemType);
    if (!inferredElemType || inferredElemType->isUnknown()) {
      if (t && !t->isUnknown()) inferredElemType = t;
      continue;
    }

    if (!t || !inferredElemType->equals(t)) {
      if ((isVoidPointerType(inferredElemType) &&
           isAssignable(t, inferredElemType)) ||
          (isVoidPointerType(expectedElemType) && isAssignable(t, expectedElemType))) {
        continue;
      }
      error(expr->loc,
            "Inconsistent element types in array literal. Expected type `" +
                inferredElemType->toString() + "` but found `" +
                (t ? t->toString() : "unknown") + "`");
    }
  }

  if (!inferredElemType || inferredElemType->isUnknown()) {
    inferredElemType = Type::makeUnknown();
  }

  TypePtr res;
  if (hasExpectedContainer && expectedElemType) {
    res = expectedType;
  } else if (hasExpectedContainer && expectedType->isSlice()) {
    res = Type::makeSlice(inferredElemType);
  } else {
    res = Type::makeArray(inferredElemType,
                          static_cast<int>(expr->elements.size()));
  }
  expr->inferredType = res;
  return res;
}

TypePtr TypeChecker::checkMapLiteralExpr(std::shared_ptr<MapLiteralExprAST> expr, TypePtr expectedType) {
  if (expr->entries.empty()) {
    if (expectedType && expectedType->isHashMap()) {
      expr->inferredType = expectedType;
      return expectedType;
    }
    TypePtr unknownMap =
        Type::makeHashMap(Type::makeUnknown(), Type::makeUnknown());
    expr->inferredType = unknownMap;
    return unknownMap;
  }

  TypePtr firstKeyType = checkExpression(expr->entries[0].first);
  TypePtr firstValType = checkExpression(expr->entries[0].second);

  for (size_t i = 1; i < expr->entries.size(); ++i) {
    TypePtr kType = checkExpression(expr->entries[i].first);
    TypePtr vType = checkExpression(expr->entries[i].second);
    if (!firstKeyType->equals(kType)) {
      error(expr->loc, "Inconsistent key types in hashmap literal");
    }
    if (!firstValType->equals(vType)) {
      error(expr->loc, "Inconsistent value types in hashmap literal");
    }
  }

  if (expectedType && expectedType->isHashMap()) {
    expr->inferredType = expectedType;
    return expectedType;
  }

  TypePtr res = Type::makeHashMap(firstKeyType, firstValType);
  expr->inferredType = res;
  return res;
}

TypePtr TypeChecker::checkIndexExpr(std::shared_ptr<IndexExprAST> expr) {
  TypePtr targetType = checkExpression(expr->target);
  TypePtr indexType = checkExpression(expr->index);

  if ((isCoreListType(targetType) || isStdListType(targetType)) &&
      targetType->typeArgs.size() == 1) {
    if (!isIntegerPrimitive(indexType)) {
      error(expr->loc, "List index must be an integer");
    }
    expr->inferredType = targetType->typeArgs.front();
    return expr->inferredType;
  }

  if (targetType->isArray() || targetType->isSlice()) {
    expr->inferredType = targetType->elementType;
    return targetType->elementType;
  } else if (targetType->isTuple()) {
    if (auto numLit =
            std::dynamic_pointer_cast<IntegerLiteralExprAST>(expr->index)) {
      try {
        size_t idx = static_cast<size_t>(std::stoul(numLit->value));
        if (idx < targetType->tupleElementTypes.size()) {
          expr->inferredType = targetType->tupleElementTypes[idx];
          return targetType->tupleElementTypes[idx];
        }
      } catch (...) {
      }
    }
    TypePtr elemTy = !targetType->tupleElementTypes.empty()
                         ? targetType->tupleElementTypes[0]
                         : Type::makePrimitive("int");
    expr->inferredType = elemTy;
    return elemTy;
  } else if (targetType->isHashMap()) {
    if (targetType->keyType && indexType &&
        !isAssignable(indexType, targetType->keyType)) {
      error(expr->loc, "Hashmap key has type '" + indexType->toString() +
                           "', expected '" +
                           targetType->keyType->toString() + "'");
    }
    TypePtr lookupType = Type::makeTuple(
        {targetType->elementType, Type::makePrimitive("bool")});
    expr->inferredType = lookupType;
    return lookupType;
  } else if (targetType->isPointer()) {
    expr->inferredType = targetType->pointerBase;
    return targetType->pointerBase;
  } else {
    error(expr->loc,
          "Indexing non-array/map type '" + targetType->toString() + "'");
    expr->inferredType = Type::makeError();
    return expr->inferredType;
  }
}

TypePtr TypeChecker::checkSliceExpr(std::shared_ptr<SliceExprAST> expr) {
  TypePtr targetType = checkExpression(expr->target);
  if (expr->startExpr) checkExpression(expr->startExpr);
  if (expr->endExpr) checkExpression(expr->endExpr);

  if (targetType->isArray() || targetType->isSlice()) {
    TypePtr sliceType = Type::makeSlice(targetType->elementType);
    expr->inferredType = sliceType;
    return sliceType;
  } else {
    error(expr->loc,
          "Slicing non-array/slice type '" + targetType->toString() + "'");
    expr->inferredType = Type::makeError();
    return expr->inferredType;
  }
}

}  // namespace Glang
