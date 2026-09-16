#include "compiler/TypeChecker.hpp"
#include "compiler/Lexer.hpp"
#include "compiler/Parser.hpp"
#include <fstream>
#include <algorithm>

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

static bool hasAttribute(const std::vector<Attribute>& attrs, const std::string& name) {
  for (const auto& a : attrs) {
    if (a.name == name) return true;
  }
  return false;
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
  m_result.errors.emplace_back(loc, msg, token);
}

TypePtr TypeChecker::resolveTypeAST(TypeASTPtr ast) {
  if (!ast) return Type::makeUnknown();

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
    return f;
  }

  Symbol* sym = m_symbolTable.lookupType(ast->name);
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
    if (resolved) {
      auto aliasType = Type::makeAlias(sym->name, resolved);
      if (ast->isConst) aliasType->isConst = true;
      return aliasType;
    }
    return Type::makeError();
  }

  auto type = sym->type;
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

void TypeChecker::instantiateType(TypePtr type, const Location& loc) {
  if (!type || (!type->isStruct() && !type->isUnion()) ||
      type->typeArgs.empty())
    return;

  for (const auto& arg : type->typeArgs) {
    if (containsGenericParam(arg)) return;
  }

  for (const auto& arg : type->typeArgs) {
    if (arg && (arg->isStruct() || arg->isUnion()) && !arg->typeArgs.empty()) {
      instantiateType(arg, loc);
    }
  }

  std::string key = type->toString();

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

      std::vector<Type::Field> realFields;
      for (const auto& f : templateDecl->fields) {
        TypePtr fType = resolveTypeAST(f.typeAst);
        realFields.push_back({f.name, fType});
      }
      type->fields = realFields;

      if (m_instantiatedTypeKeys.find(key) != m_instantiatedTypeKeys.end()) {
        m_symbolTable.exitScope();
        return;
      }
      m_instantiatedTypeKeys.insert(key);

      m_result.instantiatedTypes.push_back(type);

      std::vector<StructField> instFields;
      for (const auto& f : templateDecl->fields) {
        TypePtr fType = resolveTypeAST(f.typeAst);
        instFields.push_back({f.name, makeTypeASTFromType(fType, loc)});
      }
      m_symbolTable.exitScope();

      for (const auto& rf : realFields) {
        TypePtr inner = rf.type;
        while (inner && inner->isPointer()) inner = inner->pointerBase;
        if (inner && (inner->isStruct() || inner->isUnion()) && !inner->typeArgs.empty()) {
          instantiateType(inner, loc);
        }
      }

      auto instStruct = std::make_shared<StructDeclAST>(
          loc, key, std::vector<std::string>{}, instFields);
      m_result.astNodesToCodeGen.push_back(instStruct);
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

      if (m_instantiatedTypeKeys.find(key) != m_instantiatedTypeKeys.end()) {
        m_symbolTable.exitScope();
        return;
      }
      m_instantiatedTypeKeys.insert(key);

      m_result.instantiatedTypes.push_back(type);

      std::vector<StructField> instFields;
      for (const auto& f : templateDecl->fields) {
        TypePtr fType = resolveTypeAST(f.typeAst);
        instFields.push_back({f.name, makeTypeASTFromType(fType, loc)});
      }
      m_symbolTable.exitScope();

      for (const auto& rf : realFields) {
        TypePtr inner = rf.type;
        while (inner && inner->isPointer()) inner = inner->pointerBase;
        if (inner && (inner->isStruct() || inner->isUnion()) && !inner->typeArgs.empty()) {
          instantiateType(inner, loc);
        }
      }

      auto instUnion = std::make_shared<UnionDeclAST>(
          loc, key, std::vector<std::string>{}, instFields);
      m_result.astNodesToCodeGen.push_back(instUnion);
    }
  }
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

  std::string key = fDecl->ownerTypeName.empty()
                        ? fDecl->name
                        : (fDecl->ownerTypeName + "::" + fDecl->name);
  if (!bindings.empty()) {
    key += "<";
    bool first = true;
    for (const auto& kv : bindings) {
      if (!first) key += ", ";
      key += kv.second ? kv.second->toString() : "?";
      first = false;
    }
    key += ">";
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
    if (p.isVariadic && pType && !pType->isArray() && !pType->isSlice()) {
      pType = Type::makeSlice(pType);
    }
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

  if (m_instantiatedFuncKeys.find(key) != m_instantiatedFuncKeys.end()) {
    m_symbolTable.exitScope();
    return instMangled;
  }
  m_instantiatedFuncKeys.insert(key);

  TypePtr retType = resolveTypeAST(fDecl->returnTypeAst);
  TypePtr subRetType =
      retType ? retType->substitute(bindings) : Type::makePrimitive("void");
  TypeASTPtr instRetAst = makeTypeASTFromType(subRetType, loc);

  auto instFunc = std::make_shared<FunctionDeclAST>(
      loc, fDecl->name, scopedOwner,
      std::vector<std::string>{},  // empty typeParams -> concrete
      instParams, instRetAst, fDecl->body, fDecl->isShorthand);

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

void TypeChecker::registerTypes(std::shared_ptr<ProgramAST> program) {
  for (const auto& decl : program->declarations) {
    if (auto sDecl = std::dynamic_pointer_cast<StructDeclAST>(decl)) {
      std::vector<TypePtr> typeParams;
      for (const auto& tp : sDecl->typeParams) {
        typeParams.push_back(Type::makeGenericParam(tp));
      }
      auto stType = Type::makeStruct(sDecl->name, typeParams);
      m_symbolTable.defineType(sDecl->name, stType);
      if (!sDecl->typeParams.empty()) {
        m_genericStructDecls[sDecl->name] = sDecl;
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
        sym->type->fields.clear();
        for (const auto& f : sDecl->fields) {
          sym->type->fields.push_back({f.name, resolveTypeAST(f.typeAst)});
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
        for (const auto& f : uDecl->fields) {
          sym->type->fields.push_back({f.name, resolveTypeAST(f.typeAst)});
        }
        m_symbolTable.exitScope();
      }
    }
  }
}

void TypeChecker::registerFunctions(std::shared_ptr<ProgramAST> program) {
  for (const auto& decl : program->declarations) {
    if (auto fDecl = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
      m_symbolTable.enterScope();
      for (const auto& tp : fDecl->typeParams) {
        m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
      }
      std::vector<TypePtr> pTypes;
      for (const auto& p : fDecl->parameters) {
        TypePtr pType = resolveTypeAST(p.typeAst);
        if (p.isVariadic && pType && !pType->isArray() && !pType->isSlice()) {
          pType = Type::makeSlice(pType);
        }
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
      } else if (isCurrentExtern && extLinkName.empty()) {
        mangled = fDecl->name;
      } else {
        mangled = mangleFunctionName(fDecl->name, fDecl->ownerTypeName, pTypes);
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
        TypePtr initType = checkExpression(vStmt->initializer);
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

      // Check circular import
      if (m_activeImports.count(modPath) > 0) {
        std::string cycleStr;
        for (const auto& active : m_importStack) {
          cycleStr += active + " -> ";
        }
        cycleStr += modPath;
        error(importStmt.loc, "Circular import detected: " + cycleStr);
        continue;
      }

      // Load and check imported module if not already imported
      if (m_importedModules.count(modPath) == 0) {
        std::string sourceCode;
        auto it = m_virtualModuleSources.find(modPath);
        if (it != m_virtualModuleSources.end()) {
          sourceCode = it->second;
        } else {
          // Try loading from file system e.g. geometry.cl or std/stdio.cl
          std::string relativePath = modPath;
          for (char& c : relativePath) {
            if (c == '.') c = '/';
          }
          relativePath += ".cl";

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
          for (const auto& err : modLexer.errors()) {
            error(importStmt.loc,
                  "Import error in '" + modPath + "': " + err.message,
                  err.token);
          }
          continue;
        }

        if (modParser.hasErrors()) {
          for (const auto& err : modParser.errors()) {
            error(importStmt.loc,
                  "Import error in '" + modPath + "': " + err.message,
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

        m_importStack.pop_back();
        m_activeImports.erase(modPath);
        m_importedModules.insert(modPath);
      }

      // Selective import check
      if (!item.selectiveSymbols.empty()) {
        for (const auto& symName : item.selectiveSymbols) {
          Symbol* symVar = m_symbolTable.lookupVar(symName);
          Symbol* symType = m_symbolTable.lookupType(symName);
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
  m_instantiatedTypeKeys.clear();
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
         n == "long" || n == "ulong" || n == "char" || n == "uchar" ||
         n == "bool";
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
       effTarget->pointerBase->isClosure()))
    effTarget = effTarget->pointerBase;
  if (effSrc->isPointer() && effSrc->pointerBase &&
      (effSrc->pointerBase->isFunction() || effSrc->pointerBase->isClosure()))
    effSrc = effSrc->pointerBase;

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

  if (target->isTuple() && src->isTuple()) {
    if (target->tupleElementTypes.size() != src->tupleElementTypes.size()) {
      return false;
    }
    for (size_t i = 0; i < target->tupleElementTypes.size(); ++i) {
      if (!isAssignable(src->tupleElementTypes[i],
                        target->tupleElementTypes[i])) {
        return false;
      }
    }
    return true;
  }

  if (target->isPointer() && src->isPointer()) {
    return true;
  }

  if ((target->isStruct() || target->isUnion()) &&
      (src->isStruct() || src->isUnion())) {
    if (target->name == src->name &&
        target->typeArgs.size() == src->typeArgs.size()) {
      bool allOk = true;
      for (size_t i = 0; i < target->typeArgs.size(); ++i) {
        if (!isAssignable(src->typeArgs[i], target->typeArgs[i])) {
          allOk = false;
          break;
        }
      }
      if (allOk) return true;
    }
  }

  if ((target->isArray() || target->isSlice()) &&
      (src->isArray() || src->isSlice())) {
    if (target->elementType && src->elementType) {
      return isAssignable(src->elementType, target->elementType);
    }
    return true;
  }

  if (target->isHashMap() && src->isHashMap()) {
    if (target->keyType && src->keyType && target->elementType &&
        src->elementType) {
      return isAssignable(src->keyType, target->keyType) &&
             isAssignable(src->elementType, target->elementType);
    }
    return true;
  }

  if (isFloatType(target) && isIntegerType(src)) {
    return true;
  }

  if (isFloatType(target) && isFloatType(src)) {
    return true;
  }

  if (isIntegerType(target) && isIntegerType(src)) {
    return true;
  }

  if (target->isGenericParam() || src->isGenericParam()) {
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

    if (hasAttribute(fDecl->attributes, "userLiteral")) {
      if (fDecl->parameters.size() != 1) {
        error(fDecl->loc, "User defined literal function '" + fDecl->name +
                              "' must take exactly 1 parameter");
      }
    }

    // Register and verify parameters
    std::vector<TypePtr> pTypes;
    for (const auto& p : fDecl->parameters) {
      TypePtr pType = resolveTypeAST(p.typeAst);
      if (p.isVariadic && pType && !pType->isArray() && !pType->isSlice()) {
        pType = Type::makeSlice(pType);
      }
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
    m_currentReturnType = expectedRet;
    m_hasReturnStmt = false;

    if (fDecl->body) {
      TypePtr bodyType;
      if (auto arrLit =
              std::dynamic_pointer_cast<ArrayLiteralExprAST>(fDecl->body)) {
        bodyType = checkArrayLiteralExpr(arrLit, expectedRet);
      } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(
                     fDecl->body)) {
        bodyType = checkMapLiteralExpr(mapLit, expectedRet);
      } else {
        bodyType = checkExpression(fDecl->body);
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

  if (auto vStmt = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
    for (const auto& attr : vStmt->attributes) {
      for (const auto& arg : attr.args) {
        if (arg.value) {
          checkExpression(arg.value);
        }
      }
    }
    TypePtr declType =
        vStmt->typeAst ? resolveTypeAST(vStmt->typeAst) : nullptr;
    TypePtr initType = nullptr;

    if (vStmt->initializer) {
      if (auto arrLit = std::dynamic_pointer_cast<ArrayLiteralExprAST>(
              vStmt->initializer)) {
        initType = checkArrayLiteralExpr(arrLit, declType);
      } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(
                     vStmt->initializer)) {
        initType = checkMapLiteralExpr(mapLit, declType);
      } else {
        initType = checkExpression(vStmt->initializer);
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
      if (!isAssignable(initType, declType)) {
        error(vStmt->loc, "Cannot initialize variable '" + vStmt->name +
                              "' of type '" + declType->toString() +
                              "' with expression of type '" +
                              initType->toString() + "'");
      }
    }

    vStmt->inferredType = declType;
    if (declType && declType->kind != TypeKind::Error) {
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
      retValType = checkExpression(rStmt->value);
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
      yStmt->inferredType = checkExpression(yStmt->value);
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

TypePtr TypeChecker::checkExpression(ExprPtr expr) {
  if (!expr) return Type::makePrimitive("void");

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
    type = checkArrayLiteralExpr(arrLit);
  } else if (auto mapLit = std::dynamic_pointer_cast<MapLiteralExprAST>(expr)) {
    type = checkMapLiteralExpr(mapLit);
  } else if (auto idxExpr = std::dynamic_pointer_cast<IndexExprAST>(expr)) {
    type = checkIndexExpr(idxExpr);
  } else if (auto slcExpr = std::dynamic_pointer_cast<SliceExprAST>(expr)) {
    type = checkSliceExpr(slcExpr);
  } else if (auto unExpr = std::dynamic_pointer_cast<UnaryExprAST>(expr)) {
    type = checkUnaryExpr(unExpr);
  } else if (auto callExpr = std::dynamic_pointer_cast<CallExprAST>(expr)) {
    type = checkCallExpr(callExpr);
  } else if (auto smCall =
                 std::dynamic_pointer_cast<StaticMethodCallExprAST>(expr)) {
    type = checkStaticMethodCallExpr(smCall);
  } else if (auto memAcc =
                 std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) {
    type = checkMemberAccessExpr(memAcc);
  } else if (auto stInit = std::dynamic_pointer_cast<StructInitExprAST>(expr)) {
    type = checkStructInitExpr(stInit);
  } else if (auto ifExpr = std::dynamic_pointer_cast<IfExprAST>(expr)) {
    type = checkIfExpr(ifExpr);
  } else if (auto swExpr = std::dynamic_pointer_cast<SwitchExprAST>(expr)) {
    type = checkSwitchExpr(swExpr);
  } else if (auto blkExpr = std::dynamic_pointer_cast<BlockExprAST>(expr)) {
    type = checkBlockExpr(blkExpr);
  } else if (auto clsExpr = std::dynamic_pointer_cast<ClosureExprAST>(expr)) {
    type = checkClosureExpr(clsExpr);
  } else if (auto assExpr = std::dynamic_pointer_cast<AssignExprAST>(expr)) {
    type = checkAssignExpr(assExpr);
  } else if (auto castExpr = std::dynamic_pointer_cast<CastExprAST>(expr)) {
    type = checkCastExpr(castExpr);
  } else if (auto tupExpr =
                 std::dynamic_pointer_cast<TupleLiteralExprAST>(expr)) {
    type = checkTupleLiteralExpr(tupExpr);
  } else if (auto yieldExpr = std::dynamic_pointer_cast<YieldExprAST>(expr)) {
    type = checkExpression(yieldExpr->yieldedExpr);
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
         n == "long" || n == "ulong" || n == "char" || n == "uchar" ||
         n == "float" || n == "double";
}

static bool isIntegerPrimitive(TypePtr t) {
  if (!t) return false;
  t = t->underlyingType();
  if (!t || !t->isPrimitive()) return false;
  const std::string& n = t->name;
  return n == "int" || n == "uint" || n == "short" || n == "ushort" ||
         n == "long" || n == "ulong" || n == "char" || n == "uchar" ||
         n == "bool";
}

static bool isAggregateType(TypePtr t) {
  if (!t) return false;
  return t->isStruct() || t->isUnion() || t->isArray() || t->isSlice() ||
         t->isHashMap() || t->isTuple() || t->isFunction() || t->isClosure();
}

TypePtr TypeChecker::checkBinaryExpr(std::shared_ptr<BinaryExprAST> expr) {
  TypePtr lType = checkExpression(expr->left);
  TypePtr rType = checkExpression(expr->right);

  if (!lType || !rType) return Type::makeError();
  if (lType->kind == TypeKind::Error || rType->kind == TypeKind::Error)
    return Type::makeError();

  const std::string& op = expr->op;

  if (op == "==" || op == "!=") {
    if (isAggregateType(lType) || isAggregateType(rType)) {
      if (!lType->equals(rType)) {
        error(expr->loc, "Cannot compare incompatible aggregate types '" +
                             lType->toString() + "' and '" + rType->toString() +
                             "'");
        return Type::makeError();
      }
    }
    return Type::makePrimitive("bool");
  }

  if (op == "<" || op == "<=" || op == ">" || op == ">=") {
    if (isAggregateType(lType) || isAggregateType(rType)) {
      error(expr->loc, "Cannot perform relational comparison '" + op +
                           "' on aggregate types '" + lType->toString() +
                           "' and '" + rType->toString() + "'");
      return Type::makeError();
    }
    return Type::makePrimitive("bool");
  }

  if (op == "&&" || op == "||") {
    if (isAggregateType(lType) || isAggregateType(rType)) {
      error(expr->loc,
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
    error(expr->loc, "Invalid binary '+' on types '" + lType->toString() +
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
    error(expr->loc, "Invalid binary '-' on types '" + lType->toString() +
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
    error(expr->loc, "Invalid operator '" + op + "' on types '" +
                         lType->toString() + "' and '" + rType->toString() +
                         "'");
    return Type::makeError();
  }

  if (op == "&" || op == "|" || op == "^" || op == "<<" || op == ">>") {
    if (isIntegerPrimitive(lType) && isIntegerPrimitive(rType)) {
      return lType;
    }
    error(expr->loc,
          "Bitwise operator '" + op + "' requires integer operands, got '" +
              lType->toString() + "' and '" + rType->toString() + "'");
    return Type::makeError();
  }

  error(expr->loc, "Unsupported binary operator '" + op + "' on types '" +
                       lType->toString() + "' and '" + rType->toString() + "'");
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

  if (expr->op == "&") {
    return Type::makePointer(subType, false);
  }
  if (expr->op == "*") {
    if (subType->isPointer() && subType->pointerBase) {
      return subType->pointerBase;
    }
    error(expr->loc,
          "Cannot dereference non-pointer type '" + subType->toString() + "'");
    return Type::makeError();
  }
  if (expr->op == "!") {
    if (isAggregateType(subType)) {
      error(expr->loc, "Cannot apply '!' operator to aggregate type '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    return Type::makePrimitive("bool");
  }
  if (expr->op == "~") {
    if (!isIntegerPrimitive(subType)) {
      error(expr->loc, "Bitwise NOT '~' requires integer type, got '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    return subType;
  }
  if (expr->op == "-" || expr->op == "+") {
    if (!isNumericPrimitive(subType)) {
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
      error(expr->loc, "Increment/decrement operator '" + expr->op +
                           "' requires numeric or pointer type, got '" +
                           subType->toString() + "'");
      return Type::makeError();
    }
    return subType;
  }

  return subType;
}

bool TypeChecker::deduceTemplateArgs(TypePtr paramType, TypePtr argType, std::map<std::string, TypePtr>& bindings) {
  if (!paramType || !argType) return false;

  if (paramType->kind == TypeKind::GenericParam) {
    bindings[paramType->name] = argType;
    return true;
  }

  TypePtr effParam = (paramType->isPointer() && paramType->pointerBase &&
                      (paramType->pointerBase->isFunction() ||
                       paramType->pointerBase->isClosure()))
                         ? paramType->pointerBase
                         : paramType;
  TypePtr effArg = (argType->isPointer() && argType->pointerBase &&
                    (argType->pointerBase->isFunction() ||
                     argType->pointerBase->isClosure()))
                       ? argType->pointerBase
                       : argType;

  if (effParam->isPointer() && effArg->isPointer()) {
    return deduceTemplateArgs(effParam->pointerBase, effArg->pointerBase,
                              bindings);
  }

  if (effParam->isPointer() && !effArg->isPointer()) {
    return deduceTemplateArgs(effParam->pointerBase, effArg, bindings);
  }

  if (!effParam->isPointer() && effArg->isPointer()) {
    return deduceTemplateArgs(effParam, effArg->pointerBase, bindings);
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

TypeChecker::FunctionOverloadMatch TypeChecker::findBestDirectFunctionOverload(
    std::shared_ptr<CallExprAST> expr, const std::vector<Symbol*>& funcs) {
  FunctionOverloadMatch result;
  int maxScore = -1;

  for (Symbol* fnSym : funcs) {
    if (!fnSym->type || !fnSym->type->isFunction()) continue;
    auto fType = fnSym->type;
    bool isVariadic = fnSym->funcAST && !fnSym->funcAST->parameters.empty() &&
                      fnSym->funcAST->parameters.back().isVariadic;
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

    auto variadicType = fType->paramTypes.back();
    if (isVariadic && variadicType->isArray()) {
      int var_args_start = fType->paramTypes.size() - 1;

      for (size_t i = 0; i < var_args_start; ++i) {
        TypePtr argT = checkExpression(expr->arguments[i]);
        argTypes.push_back(argT);
        if (fnSym->funcAST && i < fType->paramTypes.size()) {
          deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
        }
      }

      auto expectedType = fType->paramTypes.back();

      std::vector<ExprPtr> args;

      if (auto arr = std::dynamic_pointer_cast<ArrayLiteralExprAST>(
              expr->arguments.back())) {
        for (int i = 0; i < arr->elements.size(); ++i) {
          args.push_back(arr->elements[i]);
        }
      } else {
        for (int i = var_args_start; i < expr->arguments.size(); ++i) {
          args.push_back(expr->arguments[i]);
        }
      }
      ArrayLiteralExprAST targetArray(expr->loc, args);
      TypePtr targetType = expectedType->elementType;

      for (size_t i = 0; i < targetArray.elements.size(); ++i) {
        TypePtr argT = checkExpression(targetArray.elements[i]);
        if (!isVariadicArgAssignable(argT, targetType)) {
          error(expr->loc,
                "Invalid type passed to variadic parameter. Expected `" +
                    targetType->toString() + "` but `" + argT->toString() +
                    "` was provided");
        }
      }
      argTypes.push_back(expectedType);
    } else {
      for (size_t i = 0; i < expr->arguments.size(); ++i) {
        TypePtr argT = checkExpression(expr->arguments[i]);
        argTypes.push_back(argT);
        if (fnSym->funcAST && i < fType->paramTypes.size()) {
          deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
        }
      }
    }

    if (hasUnboundTemplateParams(fnSym->funcAST, bindings)) continue;

    bool match = true;
    int score = 0;
    for (size_t i = 0; i < argTypes.size(); ++i) {
      TypePtr expectedP = nullptr;
      if (isVariadic && i >= fixedArgCount && !fType->paramTypes.empty()) {
        expectedP = getVariadicExpectedParamType(
            isVariadic, i, fixedArgCount, fType->paramTypes.back(), argTypes,
            fType->paramTypes.size());
      } else if (i < fType->paramTypes.size()) {
        expectedP = fType->paramTypes[i];
      }
      if (!expectedP ||
          !isVariadicArgAssignable(argTypes[i],
                                   expectedP->substitute(bindings))) {
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
    const std::vector<ExprPtr>& callArgs, TypePtr functionType) {
  if (!functionType || !functionType->isFunction()) return {};

  auto fType = functionType;
  if (callArgs.size() == fType->paramTypes.size()) {
    return callArgs;
  }
  if (callArgs.size() + 1 != fType->paramTypes.size()) {
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
    std::shared_ptr<MemberAccessExprAST> memAccess) {
  UfcsOverloadMatch result;
  int maxScore = -1;

  for (Symbol* fnSym : funcs) {
    if (!fnSym->type || !fnSym->type->isFunction()) continue;
    auto fType = fnSym->type;

    std::vector<ExprPtr> fullArgs =
        buildUfcsFullArguments(memAccess, objType, expr->arguments, fType);
    if (fullArgs.empty()) continue;

    std::map<std::string, TypePtr> bindings =
        collectExplicitTemplateBindings(expr, fnSym->funcAST);

    bool match = true;
    int score = 0;
    std::vector<TypePtr> argTypes;
    for (size_t i = 0; i < fullArgs.size(); ++i) {
      TypePtr argT = checkExpression(fullArgs[i]);
      argTypes.push_back(argT);
      if (fnSym->funcAST && i < fType->paramTypes.size()) {
        deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
      }
    }

    if (hasUnboundTemplateParams(fnSym->funcAST, bindings)) continue;

    for (size_t i = 0; i < argTypes.size(); ++i) {
      TypePtr expectedP =
          (i < fType->paramTypes.size() && fType->paramTypes[i])
              ? fType->paramTypes[i]->substitute(bindings)
              : nullptr;
      if (!isAssignable(argTypes[i], expectedP)) {
        match = false;
        break;
      }
      score +=
          (argTypes[i] && expectedP && argTypes[i]->equals(expectedP)) ? 2 : 1;
    }

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
      !matchedFn->funcAST->parameters.back().isVariadic) {
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

  if (expr->arguments.size() <= fixedArgCount || explicitVariadicArray) {
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
  expr->targetParamTypes =
      matchedFn && matchedFn->type && !matchedFn->type->paramTypes.empty()
          ? matchedFn->type->paramTypes
          : std::vector<TypePtr>{};
  for (auto& paramType : expr->targetParamTypes) {
    paramType = paramType ? paramType->substitute(bindings) : nullptr;
  }
}

TypePtr TypeChecker::applyMatchedFunctionCall(
    std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
    const std::map<std::string, TypePtr>& bindings) {
  if (!matchedFn) return Type::makeError();

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
  setMatchedFunctionTarget(expr, matchedFn, bindings);
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

TypePtr TypeChecker::checkUserLiteralCall(std::shared_ptr<CallExprAST> expr) {
  const std::string& suffix = expr->literalSuffix;
  std::vector<Symbol*> funcs = m_symbolTable.lookupFunctions(suffix);
  if (funcs.empty()) {
    error(expr->loc, "Undefined user defined literal '" + suffix + "'");
    return Type::makeError();
  }

  bool hasUserLitAttr = false;
  for (Symbol* fnSym : funcs) {
    if (fnSym->funcAST &&
        hasAttribute(fnSym->funcAST->attributes, "userLiteral")) {
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

  FunctionOverloadMatch match = findBestDirectFunctionOverload(expr, funcs);
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
    std::shared_ptr<MemberAccessExprAST> memAccess) {
  TypePtr objType = checkExpression(memAccess->object);
  TypePtr rawObjType =
      (objType && objType->isPointer()) ? objType->pointerBase : objType;

  std::string ownerName = rawObjType ? rawObjType->name : "";
  if (!ownerName.empty()) {
    std::vector<Symbol*> staticMethods = m_symbolTable.lookupStaticMethods(
        ownerName, memAccess->memberName);
    if (!staticMethods.empty()) {
      UfcsOverloadMatch match =
          findBestUfcsFunctionOverload(expr, objType, staticMethods, memAccess);
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
        findBestUfcsFunctionOverload(expr, objType, funcs, memAccess);
    if (match.function) {
      return finalizeUfcsMatchedCall(expr, match.function, match.bindings,
                                     match.fullArguments);
    }
    reportUfcsCallMismatchErrors(expr, memAccess, funcs);
    return Type::makeError();
  }

  if (rawObjType && (rawObjType->isStruct() || rawObjType->isUnion())) {
    for (const auto& field : rawObjType->fields) {
      if (field.name != memAccess->memberName || !field.type ||
          (!field.type->isFunction() && !field.type->isClosure())) {
        continue;
      }
      auto fType = field.type;
      if (expr->arguments.size() != fType->paramTypes.size()) {
        error(expr->loc, "Function field '" + memAccess->memberName +
                             "' expected " +
                             std::to_string(fType->paramTypes.size()) +
                             " arguments, but got " +
                             std::to_string(expr->arguments.size()));
        return Type::makeError();
      }
      for (size_t i = 0; i < expr->arguments.size(); ++i) {
        TypePtr argT = checkExpression(expr->arguments[i]);
        if (!isAssignable(argT, fType->paramTypes[i])) {
          error(expr->loc,
                "Type mismatch for argument " + std::to_string(i + 1) +
                    " in call to field '" + memAccess->memberName + "'");
        }
      }
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
    std::shared_ptr<IdentifierExprAST> ident) {
  std::vector<Symbol*> funcs = m_symbolTable.lookupFunctions(ident->name);
  if (funcs.empty()) {
    return checkCallableExprCall(expr);
  }

  FunctionOverloadMatch match = findBestDirectFunctionOverload(expr, funcs);
  if (match.function) {
    return applyMatchedFunctionCall(expr, match.function, match.bindings);
  }

  reportDirectCallMismatchErrors(expr, funcs[0], ident->name);
  return Type::makeError();
}

TypePtr TypeChecker::checkCallableExprCall(std::shared_ptr<CallExprAST> expr) {
  TypePtr calleeType = checkExpression(expr->callee);

  if (calleeType && (calleeType->isClosure() || calleeType->isFunction())) {
    if (expr->arguments.size() != calleeType->paramTypes.size()) {
      error(expr->loc, "Callable expected " +
                           std::to_string(calleeType->paramTypes.size()) +
                           " arguments, but got " +
                           std::to_string(expr->arguments.size()));
      return Type::makeError();
    }
    for (size_t i = 0; i < expr->arguments.size(); ++i) {
      TypePtr argT = checkExpression(expr->arguments[i]);
      if (!isAssignable(argT, calleeType->paramTypes[i])) {
        error(expr->loc, "Type mismatch for argument " + std::to_string(i + 1) +
                             " in call: cannot convert '" +
                             (argT ? argT->toString() : "unknown") + "' to '" +
                             calleeType->paramTypes[i]->toString() + "'");
      }
    }
    return calleeType->returnType ? calleeType->returnType
                                  : Type::makePrimitive("void");
  }

  if (!calleeType || calleeType->kind == TypeKind::Error) {
    return Type::makeError();
  }

  error(expr->loc, "Expression is not callable");
  return Type::makeError();
}

TypePtr TypeChecker::checkCallExpr(std::shared_ptr<CallExprAST> expr) {
  if (expr->isUserLiteral) {
    return checkUserLiteralCall(expr);
  }

  if (auto memAccess =
          std::dynamic_pointer_cast<MemberAccessExprAST>(expr->callee)) {
    return checkMemberAccessCall(expr, memAccess);
  }

  if (auto ident = std::dynamic_pointer_cast<IdentifierExprAST>(expr->callee)) {
    return checkIdentifierCall(expr, ident);
  }

  return checkCallableExprCall(expr);
}

TypePtr TypeChecker::checkStaticMethodCallExpr(std::shared_ptr<StaticMethodCallExprAST> expr) {
  std::vector<Symbol*> smSyms =
      m_symbolTable.lookupStaticMethods(expr->targetType, expr->methodName);
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
        bindings[smSym->funcAST->typeParams[i]] =
            resolveTypeAST(expr->templateArgs[i]);
      }
    }

    bool valid = true;
    int score = 0;
    for (size_t i = 0; i < expr->arguments.size(); ++i) {
      TypePtr argT = checkExpression(expr->arguments[i]);
      if (smSym->funcAST && i < fType->paramTypes.size())
        deduceTemplateArgs(fType->paramTypes[i], argT, bindings);
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

    Symbol* typeSym = m_symbolTable.lookupType(expr->targetType);
    if (typeSym && typeSym->type && typeSym->type->isStruct() &&
        !typeSym->type->typeArgs.empty()) {
      std::vector<TypePtr> tArgs;
      for (const auto& ta : expr->templateArgs)
        tArgs.push_back(resolveTypeAST(ta));
      auto structType = Type::makeStruct(expr->targetType, tArgs);
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

  if (expr->isPointerArrow && objType && objType->isPointer()) {
    objType = objType->pointerBase;
  }

  if (objType && (objType->isStruct() || objType->isUnion())) {
    for (const auto& f : objType->fields) {
      if (f.name == expr->memberName) {
        return f.type;
      }
    }
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
    }
  }

  error(expr->loc, "Unknown member '" + expr->memberName + "' on type '" +
                       (objType ? objType->toString() : "unknown") + "'");
  return Type::makeError();
}

TypePtr TypeChecker::checkStructInitExpr(std::shared_ptr<StructInitExprAST> expr) {
  TypePtr stType = resolveTypeAST(expr->structType);

  if (expr->structType && m_genericStructDecls.count(expr->structType->name)) {
    auto templateDecl = m_genericStructDecls[expr->structType->name];
    std::map<std::string, TypePtr> bindings;

    if (!expr->structType->templateArgs.empty()) {
      for (size_t i = 0; i < expr->structType->templateArgs.size() &&
                         i < templateDecl->typeParams.size();
           ++i) {
        bindings[templateDecl->typeParams[i]] =
            resolveTypeAST(expr->structType->templateArgs[i]);
      }
    }

    for (size_t i = 0; i < expr->fieldInits.size(); ++i) {
      const auto& init = expr->fieldInits[i];
      TypePtr valType = init.second ? checkExpression(init.second) : nullptr;
      if (!valType) continue;

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
          m_symbolTable.defineType(tp, Type::makeGenericParam(tp));
        }
        TypePtr declFType = resolveTypeAST(fieldTypeAST);
        m_symbolTable.exitScope();
        if (declFType) {
          deduceTemplateArgs(declFType, valType, bindings);
        }
      }
    }

    std::vector<TypePtr> tArgs;
    for (const auto& tp : templateDecl->typeParams) {
      if (bindings.count(tp) && bindings[tp] && !bindings[tp]->isUnknown()) {
        tArgs.push_back(bindings[tp]);
      }
    }

    if (tArgs.size() != templateDecl->typeParams.size() &&
        m_currentReturnType && m_currentReturnType->name == expr->structType->name &&
        m_currentReturnType->typeArgs.size() == templateDecl->typeParams.size()) {
      tArgs = m_currentReturnType->typeArgs;
    }

    if (tArgs.size() == templateDecl->typeParams.size()) {
      stType = Type::makeStruct(expr->structType->name, tArgs);
      instantiateType(stType, expr->loc);
      expr->structType = makeTypeASTFromType(stType, expr->loc);
    }

    if (stType && stType->isStruct()) {
      for (size_t i = 0; i < expr->fieldInits.size() && i < stType->fields.size(); ++i) {
        TypePtr targetFType = stType->fields[i].type;
        ExprPtr valExpr = expr->fieldInits[i].second;
        if (targetFType && targetFType->isPointer() && valExpr &&
            valExpr->inferredType && !valExpr->inferredType->isPointer()) {
          auto addrOf = std::make_shared<UnaryExprAST>(valExpr->loc, "&", valExpr);
          addrOf->inferredType = Type::makePointer(valExpr->inferredType);
          expr->fieldInits[i].second = addrOf;
        }
      }
    }
  } else {
    for (const auto& f : expr->fieldInits) {
      if (f.second) checkExpression(f.second);
    }
  }

  expr->inferredType = stType;
  return stType;
}

TypePtr TypeChecker::checkIfExpr(std::shared_ptr<IfExprAST> expr) {
  TypePtr condType = checkExpression(expr->condition);
  TypePtr thenType = checkExpression(expr->thenBranch);
  TypePtr elseType = expr->elseBranch ? checkExpression(expr->elseBranch)
                                      : Type::makePrimitive("void");

  if (thenType->equals(elseType)) return thenType;
  return thenType;
}

TypePtr TypeChecker::checkSwitchExpr(std::shared_ptr<SwitchExprAST> expr) {
  checkExpression(expr->targetExpr);
  TypePtr resType = Type::makePrimitive("int");

  for (const auto& c : expr->cases) {
    if (c.pattern) checkExpression(c.pattern);
    if (c.body) resType = checkExpression(c.body);
  }

  return resType;
}

TypePtr TypeChecker::checkBlockExpr(std::shared_ptr<BlockExprAST> expr) {
  m_symbolTable.enterScope();

  for (const auto& stmt : expr->statements) {
    checkStatement(stmt);
  }

  TypePtr blockType = Type::makePrimitive("void");

  if (expr->yieldExpr) {  // TODO: Report an error if
    blockType = checkExpression(expr->yieldExpr);
  } else if (m_currentYieldType) {
    blockType = m_currentYieldType;
    m_currentYieldType = nullptr;
  }

  m_symbolTable.exitScope();
  return blockType;
}

TypePtr TypeChecker::checkClosureExpr(std::shared_ptr<ClosureExprAST> expr) {
  m_symbolTable.enterClosureScope();

  std::vector<TypePtr> pTypes;
  for (const auto& p : expr->params) {
    TypePtr pT =
        p.typeAst ? resolveTypeAST(p.typeAst) : Type::makePrimitive("int");
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
  TypePtr valType = checkExpression(expr->value);

  if (auto ident = std::dynamic_pointer_cast<IdentifierExprAST>(expr->target)) {
    Symbol* sym = m_symbolTable.lookupVar(ident->name);
    if (sym && sym->isConst) {
      error(expr->loc, "Cannot assign to const variable '" + ident->name + "'");
    }
  }

  if (targetType && valType && !isAssignable(valType, targetType)) {
    error(expr->loc, "Cannot assign value of type '" + valType->toString() +
                         "' to target of type '" + targetType->toString() +
                         "'");
  }

  if (expr->op != "=") {
    if (isAggregateType(targetType)) {
      error(expr->loc, "Cannot use compound assignment operator '" + expr->op +
                           "' on aggregate type '" +
                           (targetType ? targetType->toString() : "unknown") +
                           "'");
    }
  }

  return targetType;
}

TypePtr TypeChecker::checkCastExpr(std::shared_ptr<CastExprAST> expr) {
  checkExpression(expr->expr);
  TypePtr targetType = resolveTypeAST(expr->targetTypeAst);
  expr->inferredType = targetType;
  return targetType;
}

TypePtr TypeChecker::checkTupleLiteralExpr(std::shared_ptr<TupleLiteralExprAST> expr) {
  std::vector<TypePtr> elemTypes;
  for (const auto& elem : expr->elements) {
    elemTypes.push_back(checkExpression(elem));
  }
  return Type::makeTuple(elemTypes);
}

TypePtr TypeChecker::checkNullLiteralExpr(std::shared_ptr<NullLiteralExprAST> expr) {
  TypePtr nullType = Type::makePointer(Type::makePrimitive("void"));
  expr->inferredType = nullType;
  return nullType;
}

TypePtr TypeChecker::checkArrayLiteralExpr(std::shared_ptr<ArrayLiteralExprAST> expr, TypePtr expectedType) {
  if (expr->elements.empty()) {
    if (expectedType && (expectedType->isArray() || expectedType->isSlice())) {
      expr->inferredType = expectedType;
      return expectedType;
    }
    TypePtr unknownSlice = Type::makeSlice(Type::makeUnknown());
    expr->inferredType = unknownSlice;
    return unknownSlice;
  }

  TypePtr expectedElemType = nullptr;
  if (expectedType && (expectedType->isArray() || expectedType->isSlice())) {
    expectedElemType = expectedType->elementType;
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

  TypePtr firstElemType = expectedElemType;

  for (size_t i = 0; i < expr->elements.size(); ++i) {
    TypePtr t = checkExpression(expr->elements[i]);
    if (!firstElemType->equals(t)) {
      if ((isVoidPointerType(firstElemType) && isAssignable(t, firstElemType)) ||
          (isVoidPointerType(expectedElemType) && isAssignable(t, expectedElemType))) {
        continue;
      }
      error(expr->loc, "Inconsistent element types in array literal. Expected type `" + expectedType->toString() + "` but found `" + t->toString() + "`");
    }
  }

  TypePtr finalElemType = isVoidPointerType(expectedElemType) ? expectedElemType : firstElemType;
  TypePtr res =
      expectedType && (expectedType->isArray() || expectedType->isSlice())
          ? expectedType
          : Type::makeArray(finalElemType, static_cast<int>(expr->elements.size()));
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
    expr->inferredType = targetType->elementType;  // value type
    return targetType->elementType;
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
