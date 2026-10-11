#include "compiler/Parser.hpp"

namespace Glang {

Parser::Parser(std::vector<Token> tokens) : m_tokens(std::move(tokens)) {}

const Token& Parser::peek() const {
    return m_tokens[m_current];
}

const Token& Parser::peekNext() const {
    if (m_current + 1 >= m_tokens.size()) return m_tokens.back();
    return m_tokens[m_current + 1];
}

const Token& Parser::previous() const {
    if (m_current == 0) return m_tokens[0];
    return m_tokens[m_current - 1];
}

bool Parser::isAtEnd() const {
    return peek().kind == TokenKind::EndOfFile;
}

Token Parser::advance() {
    if (!isAtEnd()) m_current++;
    return previous();
}

bool Parser::check(TokenKind kind) const {
    if (isAtEnd()) return false;
    return peek().kind == kind;
}

bool Parser::match(TokenKind kind) {
    if (check(kind)) {
        advance();
        return true;
    }
    return false;
}

Token Parser::consume(TokenKind kind, const std::string& message) {
    if (check(kind)) return advance();
    error(peek().loc, message, peek().lexeme);
    return peek();
}

void Parser::error(const Location& loc, const std::string& message, const std::string& token) {
    std::string tokStr = token.empty() ? peek().lexeme : token;
    m_errors.emplace_back(message, loc.line, loc.column, loc.filename, tokStr);
}

void Parser::synchronize() {
    advance();
    while (!isAtEnd()) {
        if (previous().kind == TokenKind::Semicolon) return;
        switch (peek().kind) {
            case TokenKind::KwStruct:
            case TokenKind::KwUnion:
            case TokenKind::KwEnum:
            case TokenKind::KwIf:
            case TokenKind::KwSwitch:
            case TokenKind::KwReturn:
            case TokenKind::KwYield:
            case TokenKind::KwImport:
                return;
            default:
                break;
        }
        advance();
    }
}

TypeASTPtr Parser::parseType() {
    Location loc = peek().loc;
    bool isConst = match(TokenKind::KwConst);

    TypeASTPtr typeAst = nullptr;

    if (match(TokenKind::LParen)) {
        std::vector<TypeASTPtr> innerTypes;
        while (!isAtEnd() && !check(TokenKind::RParen)) {
            innerTypes.push_back(parseType());
            if (!match(TokenKind::Comma)) break;
        }
        consume(TokenKind::RParen, "Expected ')' in type");

        if (match(TokenKind::Arrow)) {
            TypeASTPtr retType = parseType();
            typeAst = std::make_shared<TypeASTNode>(loc, "function");
            typeAst->isFunctionType = true;
            typeAst->paramTypes = innerTypes;
            typeAst->returnType = retType;
        } else {
            typeAst = std::make_shared<TypeASTNode>(loc, "tuple");
            typeAst->isTuple = true;
            typeAst->tupleElementTypes = innerTypes;
        }
    } else {
        std::string name;
        if (match(TokenKind::KwVoid)) name = "void";
        else if (match(TokenKind::KwBool)) name = "bool";
        else if (match(TokenKind::KwChar)) name = "char";
        else if (match(TokenKind::KwUChar)) name = "uchar";
        else if (match(TokenKind::KwShort)) name = "short";
        else if (match(TokenKind::KwUShort)) name = "ushort";
        else if (match(TokenKind::KwInt)) name = "int";
        else if (match(TokenKind::KwUInt)) name = "uint";
        else if (match(TokenKind::KwLong)) name = "long";
        else if (match(TokenKind::KwULong)) name = "ulong";
        else if (match(TokenKind::KwFloat)) name = "float";
        else if (match(TokenKind::KwDouble)) name = "double";
        else if (match(TokenKind::KwAuto)) name = "auto";
        else if (check(TokenKind::Identifier)) {
            name = advance().lexeme;
            while (match(TokenKind::DoubleColon)) {
                Token member = consume(TokenKind::Identifier, "Expected identifier after '::' in type name");
                name += "::" + member.lexeme;
            }
        } else {
            error(loc, "Expected type name");
            return nullptr;
        }

        typeAst = std::make_shared<TypeASTNode>(loc, name);

        if (match(TokenKind::Less)) {
            while (!isAtEnd() && !check(TokenKind::Greater)) {
                typeAst->templateArgs.push_back(parseType());
                if (!match(TokenKind::Comma)) break;
            }
            consume(TokenKind::Greater, "Expected '>' after template arguments in type");
        }
    }

    typeAst->isConst = isConst;

    while (true) {
        if (match(TokenKind::Star)) {
            auto ptrAst = std::make_shared<TypeASTNode>(loc, typeAst->name + "*");
            ptrAst->isPointer = true;
            ptrAst->pointerBase = typeAst;
            typeAst = ptrAst;
        } else if (match(TokenKind::LBracket)) {
            if (match(TokenKind::RBracket)) {
                auto sliceAst = std::make_shared<TypeASTNode>(loc, typeAst->name + "[]");
                sliceAst->isSlice = true;
                sliceAst->elementType = typeAst;
                typeAst = sliceAst;
            } else if (check(TokenKind::IntegerLiteral)) {
                Token szTok = advance();
                consume(TokenKind::RBracket, "Expected ']' after array size");
                int sz = std::stoi(szTok.lexeme);
                auto arrAst = std::make_shared<TypeASTNode>(loc, typeAst->name + "[" + std::to_string(sz) + "]");
                arrAst->isArray = true;
                arrAst->arraySize = sz;
                arrAst->elementType = typeAst;
                typeAst = arrAst;
            } else {
                TypeASTPtr kType = parseType();
                consume(TokenKind::RBracket, "Expected ']' after hashmap key type");
                auto mapAst = std::make_shared<TypeASTNode>(loc, typeAst->name + "[" + (kType ? kType->name : "?") + "]");
                mapAst->isMap = true;
                mapAst->keyType = kType;
                mapAst->elementType = typeAst;
                typeAst = mapAst;
            }
        } else {
            break;
        }
    }

    // Check C-style function pointer modifier e.g. int (*fn)(int) or int (*)(int)
    if (check(TokenKind::LParen) && peekNext().kind == TokenKind::Star) {
        Location fnLoc = peek().loc;
        advance(); // consume '('
        advance(); // consume '*'
        std::string dName = "";
        if (check(TokenKind::Identifier)) {
            dName = advance().lexeme;
        }
        consume(TokenKind::RParen, "Expected ')' in function pointer declaration");
        consume(TokenKind::LParen, "Expected '(' for function pointer parameters");
        std::vector<TypeASTPtr> fnParams;
        while (!isAtEnd() && !check(TokenKind::RParen)) {
            fnParams.push_back(parseType());
            if (!match(TokenKind::Comma)) break;
        }
        consume(TokenKind::RParen, "Expected ')' after function pointer parameters");

        auto fnPtrAst = std::make_shared<TypeASTNode>(fnLoc, "func_ptr");
        fnPtrAst->isFunctionType = true;
        fnPtrAst->returnType = typeAst;
        fnPtrAst->paramTypes = fnParams;
        fnPtrAst->declName = dName;
        typeAst = fnPtrAst;
    }

    return typeAst;
}

ImportStmtAST Parser::parseImport() {
  Location loc = previous().loc;
  std::vector<ImportItem> items;

  while (true) {
    Token modFirst =
        consume(TokenKind::Identifier, "Expected module name after 'import'");
    std::string modPath = modFirst.lexeme;
    while (match(TokenKind::Dot)) {
      Token modNext = consume(TokenKind::Identifier,
                              "Expected identifier after '.' in module name");
      modPath += "." + modNext.lexeme;
    }

    std::vector<std::string> selective;
    if (match(TokenKind::Colon)) {
      while (true) {
        Token sym = consume(TokenKind::Identifier,
                            "Expected symbol name in selective import");
        selective.push_back(sym.lexeme);
        if (!match(TokenKind::Comma)) break;
      }
    }

    items.push_back({modPath, selective});

    if (match(TokenKind::Comma)) {
      continue;
    }
    break;
  }

    match(TokenKind::Semicolon); // consume optional semicolon
    return ImportStmtAST(loc, items);
}

std::vector<Attribute> Parser::parseAttributes() {
    std::vector<Attribute> attributes;
    while (check(TokenKind::LBracket)) {
        advance(); // consume '['
        while (!isAtEnd() && !check(TokenKind::RBracket)) {
            Location loc = peek().loc;
            Token nameTok = consume(TokenKind::Identifier, "Expected attribute name");
            Attribute attr(loc, nameTok.lexeme);
            if (match(TokenKind::LParen)) {
                while (!isAtEnd() && !check(TokenKind::RParen)) {
                    AttributeArg arg;
                    if (check(TokenKind::Identifier) && peekNext().kind == TokenKind::Assign) {
                        Token keyTok = advance();
                        consume(TokenKind::Assign, "Expected '=' after attribute argument name");
                        arg.name = keyTok.lexeme;
                        arg.value = parseExpression();
                    } else {
                        arg.value = parseExpression();
                    }
                    attr.args.push_back(arg);
                    if (!match(TokenKind::Comma)) break;
                }
                consume(TokenKind::RParen, "Expected ')' after attribute arguments");
            }
            attributes.push_back(attr);
            if (!match(TokenKind::Comma)) break;
        }
        consume(TokenKind::RBracket, "Expected ']' after attribute list");
    }
    return attributes;
}

bool Parser::isAttributeNext() {
  if (!check(TokenKind::LBracket)) return false;
  size_t savedPos = m_current;
  size_t savedErrCount = m_errors.size();
  bool isAttr = false;
  advance();  // consume '['
  if (check(TokenKind::Identifier)) {
    int depth = 1;
    size_t look = m_current;
    while (look < m_tokens.size() && depth > 0) {
      if (m_tokens[look].kind == TokenKind::LBracket)
        depth++;
      else if (m_tokens[look].kind == TokenKind::RBracket)
        depth--;
      look++;
    }
    if (depth == 0 && look < m_tokens.size()) {
      TokenKind nextKind = m_tokens[look].kind;
      if (nextKind == TokenKind::KwStruct || nextKind == TokenKind::KwUnion ||
          nextKind == TokenKind::KwEnum || nextKind == TokenKind::KwVoid ||
          nextKind == TokenKind::KwBool || nextKind == TokenKind::KwChar ||
          nextKind == TokenKind::KwUChar || nextKind == TokenKind::KwShort ||
          nextKind == TokenKind::KwUShort || nextKind == TokenKind::KwInt ||
          nextKind == TokenKind::KwUInt || nextKind == TokenKind::KwLong ||
          nextKind == TokenKind::KwULong || nextKind == TokenKind::KwFloat ||
          nextKind == TokenKind::KwDouble || nextKind == TokenKind::KwConst ||
          nextKind == TokenKind::KwAuto || nextKind == TokenKind::KwType ||
          nextKind == TokenKind::Identifier ||
          nextKind == TokenKind::LBracket) {
        isAttr = true;
      }
    }
  }
  m_current = savedPos;
  m_errors.resize(savedErrCount);
  return isAttr;
}

DeclPtr Parser::parseDeclaration() {
  std::string leadingDoc = peek().leadingDoc;
  std::vector<Attribute> attrs;
  if (check(TokenKind::LBracket)) {
    attrs = parseAttributes();
  }

  Location loc = peek().loc;
  DeclPtr decl = nullptr;
  if (check(TokenKind::KwStruct)) {
    advance();
    decl = parseStructDecl();
  } else if (check(TokenKind::KwUnion)) {
    advance();
    decl = parseUnionDecl();
  } else if (check(TokenKind::KwEnum)) {
    advance();
    decl = parseEnumDecl();
  } else if (check(TokenKind::KwType)) {
    advance();
    decl = parseTypeAliasDecl();
  } else {
    decl = parseFunctionDecl();
  }

  if (decl) {
    if (decl->doc.empty() && !leadingDoc.empty()) {
      decl->doc = leadingDoc;
    }
    if (!attrs.empty()) {
      decl->attributes = attrs;
    }
  }
  return decl;
}

DeclPtr Parser::parseStructDecl() {
  Location loc = previous().loc;
  std::string declDoc = previous().leadingDoc;
  Token nameTok = consume(TokenKind::Identifier, "Expected struct name");
  std::string name = nameTok.lexeme;
  while (match(TokenKind::DoubleColon)) {
    Token memberTok = consume(TokenKind::Identifier,
                              "Expected identifier after '::' in struct name");
    name += "::" + memberTok.lexeme;
  }
  std::vector<std::string> typeParams;

  if (match(TokenKind::Less)) {
    while (!isAtEnd() && !check(TokenKind::Greater)) {
      Token tParam = consume(TokenKind::Identifier,
                             "Expected generic type parameter name");
      typeParams.push_back(tParam.lexeme);
      if (!match(TokenKind::Comma)) break;
    }
    consume(TokenKind::Greater, "Expected '>' after generic type parameters");
  }

  consume(TokenKind::LBrace, "Expected '{' to start struct body");
  std::vector<StructField> fields;
  std::vector<std::shared_ptr<TypeAliasDeclAST>> typeAliases;

  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    if (match(TokenKind::KwType)) {
      auto alias = std::dynamic_pointer_cast<TypeAliasDeclAST>(
          parseTypeAliasDecl());
      if (alias) {
        typeAliases.push_back(std::move(alias));
      }
      continue;
    }
    std::string fieldDoc = peek().leadingDoc;
    TypeASTPtr fType = parseType();
    Token fName = consume(TokenKind::Identifier, "Expected struct field name");
    consume(TokenKind::Semicolon,
            "Expected ';' after struct field declaration");
    fields.push_back({fName.lexeme, fType, fieldDoc});
  }

  consume(TokenKind::RBrace, "Expected '}' after struct body");
  auto res = std::make_shared<StructDeclAST>(loc, name, typeParams, fields,
                                             typeAliases);
  res->doc = declDoc;
  return res;
}

DeclPtr Parser::parseUnionDecl() {
  Location loc = previous().loc;
  std::string declDoc = previous().leadingDoc;
  Token nameTok = consume(TokenKind::Identifier, "Expected union name");
  std::string name = nameTok.lexeme;
  while (match(TokenKind::DoubleColon)) {
    Token memberTok = consume(TokenKind::Identifier,
                              "Expected identifier after '::' in union name");
    name += "::" + memberTok.lexeme;
  }
  std::vector<std::string> typeParams;

  if (match(TokenKind::Less)) {
    while (!isAtEnd() && !check(TokenKind::Greater)) {
      Token tParam = consume(TokenKind::Identifier,
                             "Expected generic type parameter name");
      typeParams.push_back(tParam.lexeme);
      if (!match(TokenKind::Comma)) break;
    }
    consume(TokenKind::Greater, "Expected '>' after generic type parameters");
  }

  consume(TokenKind::LBrace, "Expected '{' to start union body");
  std::vector<StructField> fields;

  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    std::string fieldDoc = peek().leadingDoc;
    TypeASTPtr fType = parseType();
    Token fName = consume(TokenKind::Identifier, "Expected union field name");
    consume(TokenKind::Semicolon, "Expected ';' after union field declaration");
    fields.push_back({fName.lexeme, fType, fieldDoc});
  }

  consume(TokenKind::RBrace, "Expected '}' after union body");
  auto res = std::make_shared<UnionDeclAST>(loc, name, typeParams, fields);
  res->doc = declDoc;
  return res;
}

DeclPtr Parser::parseEnumDecl() {
  Location loc = previous().loc;
  std::string declDoc = previous().leadingDoc;
  Token nameTok = consume(TokenKind::Identifier, "Expected enum name");
  std::string name = nameTok.lexeme;
  while (match(TokenKind::DoubleColon)) {
    Token memberTok = consume(TokenKind::Identifier,
                              "Expected identifier after '::' in enum name");
    name += "::" + memberTok.lexeme;
  }
  consume(TokenKind::LBrace, "Expected '{' to start enum body");

  std::vector<std::string> enums;
  std::vector<EnumMember> members;
  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    std::string memberDoc = peek().leadingDoc;
    Token itemTok =
        consume(TokenKind::Identifier, "Expected enum member identifier");
    enums.push_back(itemTok.lexeme);
    members.push_back({itemTok.lexeme, memberDoc});
    match(TokenKind::Comma);
    match(TokenKind::Semicolon);
  }

  consume(TokenKind::RBrace, "Expected '}' after enum body");
  auto res = std::make_shared<EnumDeclAST>(loc, name, enums, members);
  res->doc = declDoc;
  return res;
}

DeclPtr Parser::parseTypeAliasDecl() {
  Location loc = previous().loc;
  std::string declDoc = previous().leadingDoc;
  Token nameTok =
      consume(TokenKind::Identifier, "Expected alias name after 'type'");
  std::string aliasName = nameTok.lexeme;
  std::vector<std::string> typeParams;
  if (match(TokenKind::Less)) {
    while (!isAtEnd() && !check(TokenKind::Greater)) {
      Token tParam = consume(TokenKind::Identifier,
                             "Expected generic type parameter name");
      typeParams.push_back(tParam.lexeme);
      if (!match(TokenKind::Comma)) break;
    }
    consume(TokenKind::Greater, "Expected '>' after generic type parameters");
  }
  consume(TokenKind::Assign, "Expected '=' in type alias declaration");
  TypeASTPtr targetType = parseType();
  match(TokenKind::Semicolon);
  auto res = std::make_shared<TypeAliasDeclAST>(loc, aliasName, typeParams,
                                                targetType);
  res->doc = declDoc;
  return res;
}

static bool isPrimitiveTypeKeyword(TokenKind kind) {
  return kind == TokenKind::KwInt || kind == TokenKind::KwUInt ||
         kind == TokenKind::KwBool || kind == TokenKind::KwChar ||
         kind == TokenKind::KwUChar || kind == TokenKind::KwShort ||
         kind == TokenKind::KwUShort || kind == TokenKind::KwLong ||
         kind == TokenKind::KwULong || kind == TokenKind::KwFloat ||
         kind == TokenKind::KwDouble || kind == TokenKind::KwVoid ||
         kind == TokenKind::KwAuto;
}

DeclPtr Parser::parseFunctionDecl() {
  Location loc = peek().loc;
  std::string declDoc = peek().leadingDoc;
  TypeASTPtr returnType = parseType();

  std::string funcName;
  std::string ownerType;
  std::vector<std::string> typeParams;

  Token firstIdent;
  if (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind)) {
    firstIdent = advance();
  } else {
    firstIdent = consume(TokenKind::Identifier,
                         "Expected function name or static method owner name");
  }
  if (declDoc.empty() && !firstIdent.leadingDoc.empty()) {
    declDoc = firstIdent.leadingDoc;
  }
  std::string currentName = firstIdent.lexeme;

  while (match(TokenKind::DoubleColon)) {
    Token nextIdent;
    if (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind)) {
      nextIdent = advance();
    } else {
      nextIdent =
          consume(TokenKind::Identifier, "Expected identifier after '::'");
    }
    if (!ownerType.empty()) ownerType += "::";
    ownerType += currentName;
    currentName = nextIdent.lexeme;
  }

  if (check(TokenKind::Less)) {
    size_t savedPos = m_current;
    advance();  // consume '<'
    std::vector<std::string> tParams;
    bool validGen = true;
    while (!isAtEnd() && !check(TokenKind::Greater)) {
      if (check(TokenKind::Identifier)) {
        tParams.push_back(advance().lexeme);
      } else {
        validGen = false;
        break;
      }
      if (!match(TokenKind::Comma)) break;
    }

    if (validGen && match(TokenKind::Greater)) {
      if (match(TokenKind::DoubleColon)) {
        if (!ownerType.empty()) ownerType += "::";
        ownerType += currentName;
        Token methodIdent = consume(TokenKind::Identifier,
                                    "Expected static method name after '::'");
        funcName = methodIdent.lexeme;
        typeParams = tParams;

        if (match(TokenKind::Less)) {
          while (!isAtEnd() && !check(TokenKind::Greater)) {
            Token tParam = consume(TokenKind::Identifier,
                                   "Expected template parameter name");
            typeParams.push_back(tParam.lexeme);
            if (!match(TokenKind::Comma)) break;
          }
          consume(TokenKind::Greater, "Expected '>' after template parameters");
        }
      } else {
        funcName = currentName;
        typeParams = tParams;
      }
    } else {
      m_current = savedPos;
      funcName = currentName;
    }
  } else {
    funcName = currentName;
  }

  // Parameters
  consume(TokenKind::LParen, "Expected '(' for function parameter list");
  std::vector<ParamDecl> params;
  while (!isAtEnd() && !check(TokenKind::RParen)) {
    match(TokenKind::Dot);

    TypeASTPtr pType = parseType();
    bool isVariadicParam = match(TokenKind::DotDotDot);
    if (isVariadicParam) {
      auto variadicType = std::make_shared<TypeASTNode>(
          pType ? pType->loc : peek().loc,
          pType ? (pType->name + "[]") : "auto[]");
      variadicType->isArray = true;
      variadicType->elementType = pType;
      pType = variadicType;
    }

    std::string pName;
    if (pType && !pType->declName.empty()) {
      pName = pType->declName;
    } else {
      Token pNameTok =
          consume(TokenKind::Identifier, "Expected parameter name");
      pName = pNameTok.lexeme;
    }
    params.push_back({pName, pType, isVariadicParam});
    if (!match(TokenKind::Comma)) break;
  }
  consume(TokenKind::RParen, "Expected ')' after function parameters");

  ExprPtr bodyExpr = nullptr;
  bool isShorthand = false;

  if (match(TokenKind::Semicolon)) {
    bodyExpr = nullptr;
  } else if (match(TokenKind::FatArrow)) {
    isShorthand = true;
    bodyExpr = parseExpression();
    match(TokenKind::Semicolon);  // optional semicolon for shorthand
  } else if (check(TokenKind::LBrace)) {
    bodyExpr = parseBlockExpression();
  } else {
    error(peek().loc, "Expected function body ('=>' or '{') or ';'");
  }

  auto funcDecl = std::make_shared<FunctionDeclAST>(
      loc, funcName, ownerType, typeParams, params, returnType, bodyExpr,
      isShorthand);
  funcDecl->doc = declDoc;
  funcDecl->endLoc = previous().loc;
  return funcDecl;
}

StmtPtr Parser::parseStatement() {
  Location loc = peek().loc;

  if (check(TokenKind::KwConst)) {
    advance();
    bool isStatic = false;
    if (check(TokenKind::KwStatic)) {
      advance();
      isStatic = true;
    }
    return parseVarDeclStmt(true, isStatic);
  }
  if (check(TokenKind::KwStatic)) {
    advance();
    bool isConst = false;
    if (check(TokenKind::KwConst)) {
      advance();
      isConst = true;
    }
    return parseVarDeclStmt(isConst, true);
  }
  if (check(TokenKind::KwType)) {
    advance();
    auto decl = parseTypeAliasDecl();
    if (auto aliasDecl = std::dynamic_pointer_cast<TypeAliasDeclAST>(decl)) {
      return std::make_shared<TypeAliasStmtAST>(loc, aliasDecl);
    }
  }
  if (check(TokenKind::KwReturn)) {
    advance();
    return parseReturnStmt();
  }
  if (check(TokenKind::KwYield)) {
    advance();
    return parseYieldStmt();
  }
  if (check(TokenKind::KwBreak)) {
    Location bLoc = advance().loc;
    match(TokenKind::Semicolon);
    return std::make_shared<BreakStmtAST>(bLoc);
  }
  if (check(TokenKind::KwContinue)) {
    Location cLoc = advance().loc;
    match(TokenKind::Semicolon);
    return std::make_shared<ContinueStmtAST>(cLoc);
  }
  if (check(TokenKind::KwWhile)) {
    advance();
    return parseWhileStmt();
  }
  if (check(TokenKind::KwDo)) {
    advance();
    return parseDoWhileStmt();
  }
  if (check(TokenKind::KwFor)) {
    advance();
    return parseForStmt();
  }
  if (check(TokenKind::KwDefer)) {
    advance();
    return parseDeferStmt();
  }

  size_t savedPos = m_current;
  size_t savedErrCount = m_errors.size();
  if (check(TokenKind::KwInt) || check(TokenKind::KwUInt) ||
      check(TokenKind::KwBool) || check(TokenKind::KwChar) ||
      check(TokenKind::KwUChar) || check(TokenKind::KwShort) ||
      check(TokenKind::KwUShort) || check(TokenKind::KwLong) ||
      check(TokenKind::KwULong) || check(TokenKind::KwFloat) ||
      check(TokenKind::KwDouble) || check(TokenKind::KwAuto)) {
    return parseVarDeclStmt(false);
  }

  if (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind) ||
      check(TokenKind::LParen)) {
    TypeASTPtr candidateType = parseType();
    if (candidateType &&
        (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind))) {
      std::string varName;
      if (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind)) {
        varName = advance().lexeme;
      }
      while (match(TokenKind::DoubleColon)) {
        if (check(TokenKind::Identifier) ||
            isPrimitiveTypeKeyword(peek().kind)) {
          varName += "::" + advance().lexeme;
        } else {
          Token member =
              consume(TokenKind::Identifier,
                      "Expected identifier after '::' in variable name");
          varName += "::" + member.lexeme;
        }
      }
      ExprPtr initExpr = nullptr;
      if (match(TokenKind::Assign)) {
        initExpr = parseExpression();
      }
      match(TokenKind::Semicolon);
      auto vDecl = std::make_shared<VarDeclStmtAST>(loc, varName, candidateType,
                                                    initExpr, false);
      vDecl->doc = loc.filename.empty() ? "" : peek().leadingDoc;  // assign doc
      return vDecl;
    }

    m_current = savedPos;
    m_errors.resize(savedErrCount);
  }

  ExprPtr expr = parseExpression();
  match(TokenKind::Semicolon);
  return std::make_shared<ExprStmtAST>(loc, expr);
}

StmtPtr Parser::parseVarDeclStmt(bool isConst, bool isStatic) {
  Location loc = (isConst || isStatic) ? previous().loc : peek().loc;
  std::string doc =
      (isConst || isStatic) ? previous().leadingDoc : peek().leadingDoc;
  TypeASTPtr typeAst = parseType();
  std::string varName;
  if (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind)) {
    varName = advance().lexeme;
  } else {
    Token varNameTok =
        consume(TokenKind::Identifier, "Expected variable name in declaration");
    varName = varNameTok.lexeme;
  }
  while (match(TokenKind::DoubleColon)) {
    if (check(TokenKind::Identifier) || isPrimitiveTypeKeyword(peek().kind)) {
      varName += "::" + advance().lexeme;
    } else {
      Token member = consume(TokenKind::Identifier,
                             "Expected identifier after '::' in variable name");
      varName += "::" + member.lexeme;
    }
  }

  ExprPtr initExpr = nullptr;
  if (match(TokenKind::Assign)) {
    initExpr = parseExpression();
  }
  match(TokenKind::Semicolon);
  auto varDecl = std::make_shared<VarDeclStmtAST>(loc, varName, typeAst,
                                                  initExpr, isConst, isStatic);
  varDecl->doc = doc;
  return varDecl;
}

StmtPtr Parser::parseReturnStmt() {
  Location loc = previous().loc;
  ExprPtr val = nullptr;
  if (!check(TokenKind::Semicolon)) {
    val = parseExpression();
  }
  match(TokenKind::Semicolon);
  return std::make_shared<ReturnStmtAST>(loc, val);
}

StmtPtr Parser::parseYieldStmt() {
  Location loc = previous().loc;
  ExprPtr val = parseExpression();
  match(TokenKind::Semicolon);
  return std::make_shared<YieldStmtAST>(loc, val);
}

StmtPtr Parser::parseWhileStmt() {
  Location loc = previous().loc;  // after 'while'
  consume(TokenKind::LParen, "Expected '(' after 'while'");
  ExprPtr cond = parseExpression();
  consume(TokenKind::RParen, "Expected ')' after condition");
  StmtPtr body = parseStatement();
  return std::make_shared<WhileStmtAST>(loc, cond, body);
}

StmtPtr Parser::parseDoWhileStmt() {
  Location loc = previous().loc;  // after 'do'
  StmtPtr body = parseStatement();
  consume(TokenKind::KwWhile, "Expected 'while' after 'do' body");
  consume(TokenKind::LParen, "Expected '(' after 'while'");
  ExprPtr cond = parseExpression();
  consume(TokenKind::RParen, "Expected ')' after condition");
  match(TokenKind::Semicolon);
  return std::make_shared<DoWhileStmtAST>(loc, body, cond);
}

StmtPtr Parser::parseForStmt() {
  Location loc = previous().loc;  // after 'for'
  consume(TokenKind::LParen, "Expected '(' after 'for'");

  StmtPtr init = nullptr;
  if (!match(TokenKind::Semicolon)) {
    init = parseStatement();
  }

  ExprPtr cond = nullptr;
  if (!check(TokenKind::Semicolon)) {
    cond = parseExpression();
  }
  consume(TokenKind::Semicolon, "Expected ';' after for loop condition");

  ExprPtr post = nullptr;
  if (!check(TokenKind::RParen)) {
    post = parseExpression();
  }
  consume(TokenKind::RParen, "Expected ')' after for loop post expression");

  StmtPtr body = parseStatement();
  return std::make_shared<ForStmtAST>(loc, init, cond, post, body);
}

StmtPtr Parser::parseDeferStmt() {
  Location loc = previous().loc;
  StmtPtr deferredStmt = parseStatement();
  return std::make_shared<DeferStmtAST>(loc, deferredStmt);
}

ExprPtr Parser::parseExpression() { return parseAssignmentExpr(); }

ExprPtr Parser::parseAssignmentExpr() {
  ExprPtr left = parseLogicalOr();
  if (check(TokenKind::Assign) || check(TokenKind::PlusAssign) ||
      check(TokenKind::MinusAssign) || check(TokenKind::StarAssign) ||
      check(TokenKind::SlashAssign) || check(TokenKind::PercentAssign) ||
      check(TokenKind::LessLessAssign) ||
      check(TokenKind::GreaterGreaterAssign) ||
      (check(TokenKind::Greater) && peekNext().kind == TokenKind::GreaterEqual) ||
      check(TokenKind::AmpersandAssign) || check(TokenKind::PipeAssign) ||
      check(TokenKind::CaretAssign)) {
    Token opTok;
    if (check(TokenKind::Greater) && peekNext().kind == TokenKind::GreaterEqual) {
      Location loc = peek().loc;
      advance();
      advance();
      opTok = Token(TokenKind::GreaterGreaterAssign, ">>=", loc);
    } else {
      opTok = advance();
    }
    ExprPtr right = parseAssignmentExpr();
    return std::make_shared<AssignExprAST>(opTok.loc, left, right,
                                           opTok.lexeme);
  }
  return left;
}

ExprPtr Parser::parseLogicalOr() {
  ExprPtr expr = parseLogicalAnd();
  while (match(TokenKind::PipePipe)) {
    Location loc = previous().loc;
    ExprPtr right = parseLogicalAnd();
    expr = std::make_shared<BinaryExprAST>(loc, "||", expr, right);
  }
  return expr;
}

ExprPtr Parser::parseLogicalAnd() {
  ExprPtr expr = parseBitwiseOr();
  while (match(TokenKind::AndAnd)) {
    Location loc = previous().loc;
    ExprPtr right = parseBitwiseOr();
    expr = std::make_shared<BinaryExprAST>(loc, "&&", expr, right);
  }
  return expr;
}

ExprPtr Parser::parseBitwiseOr() {
  ExprPtr expr = parseBitwiseXor();
  while (match(TokenKind::Pipe)) {
    Location loc = previous().loc;
    ExprPtr right = parseBitwiseXor();
    expr = std::make_shared<BinaryExprAST>(loc, "|", expr, right);
  }
  return expr;
}

ExprPtr Parser::parseBitwiseXor() {
  ExprPtr expr = parseBitwiseAnd();
  while (match(TokenKind::Caret)) {
    Location loc = previous().loc;
    ExprPtr right = parseBitwiseAnd();
    expr = std::make_shared<BinaryExprAST>(loc, "^", expr, right);
  }
  return expr;
}

ExprPtr Parser::parseBitwiseAnd() {
  ExprPtr expr = parseEquality();
  while (match(TokenKind::Ampersand)) {
    Location loc = previous().loc;
    ExprPtr right = parseEquality();
    expr = std::make_shared<BinaryExprAST>(loc, "&", expr, right);
  }
  return expr;
}

ExprPtr Parser::parseEquality() {
  ExprPtr expr = parseRelational();
  while (check(TokenKind::Equal) || check(TokenKind::NotEqual)) {
    Token opTok = advance();
    ExprPtr right = parseRelational();
    expr =
        std::make_shared<BinaryExprAST>(opTok.loc, opTok.lexeme, expr, right);
  }
  return expr;
}

ExprPtr Parser::parseRelational() {
  ExprPtr expr = parseShift();
  while (check(TokenKind::Less) || check(TokenKind::LessEqual) ||
         check(TokenKind::Greater) || check(TokenKind::GreaterEqual)) {
    Token opTok = advance();
    ExprPtr right = parseShift();
    expr =
        std::make_shared<BinaryExprAST>(opTok.loc, opTok.lexeme, expr, right);
  }
  return expr;
}

ExprPtr Parser::parseShift() {
  ExprPtr expr = parseAdditive();
  while (check(TokenKind::LessLess) || check(TokenKind::GreaterGreater) ||
         (check(TokenKind::Greater) && peekNext().kind == TokenKind::Greater)) {
    Token opTok;
    if (match(TokenKind::LessLess)) {
      opTok = previous();
    } else if (match(TokenKind::GreaterGreater)) {
      opTok = previous();
    } else if (check(TokenKind::Greater) && peekNext().kind == TokenKind::Greater) {
      Location loc = peek().loc;
      advance();
      advance();
      opTok = Token(TokenKind::GreaterGreater, ">>", loc);
    } else {
      break;
    }
    ExprPtr right = parseAdditive();
    expr =
        std::make_shared<BinaryExprAST>(opTok.loc, opTok.lexeme, expr, right);
  }
  return expr;
}

ExprPtr Parser::parseAdditive() {
  ExprPtr expr = parseMultiplicative();
  while (check(TokenKind::Plus) || check(TokenKind::Minus)) {
    Token opTok = advance();
    ExprPtr right = parseMultiplicative();
    expr =
        std::make_shared<BinaryExprAST>(opTok.loc, opTok.lexeme, expr, right);
  }
  return expr;
}

ExprPtr Parser::parseMultiplicative() {
  ExprPtr expr = parseCast();
  while (check(TokenKind::Star) || check(TokenKind::Slash) ||
         check(TokenKind::Percent)) {
    Token opTok = advance();
    ExprPtr right = parseCast();
    expr =
        std::make_shared<BinaryExprAST>(opTok.loc, opTok.lexeme, expr, right);
  }
  return expr;
}

ExprPtr Parser::parseCast() {
  ExprPtr expr = parseUnary();
  while (match(TokenKind::KwAs)) {
    Location loc = previous().loc;
    TypeASTPtr targetType = parseType();
    expr = std::make_shared<CastExprAST>(loc, expr, targetType);
  }
  return expr;
}

ExprPtr Parser::parseUnary() {
  if (check(TokenKind::KwSizeof)) {
    Token opTok = advance();
    Location loc = opTok.loc;
    if (match(TokenKind::LParen)) {
      size_t savedPos = m_current;
      size_t savedErrCount = m_errors.size();
      TypeASTPtr typeAst = parseType();
      if (typeAst && match(TokenKind::RParen)) {
        return std::make_shared<UnaryExprAST>(loc, "sizeof", typeAst);
      }
      m_current = savedPos;
      m_errors.resize(savedErrCount);
      ExprPtr expr = parseExpression();
      consume(TokenKind::RParen, "Expected ')' after sizeof expression");
      return std::make_shared<UnaryExprAST>(loc, "sizeof", expr);
    } else {
      ExprPtr operand = parseUnary();
      return std::make_shared<UnaryExprAST>(loc, "sizeof", operand);
    }
  }

  if (check(TokenKind::Minus) || check(TokenKind::Plus) ||
      check(TokenKind::Exclamation) || check(TokenKind::Tilde) ||
      check(TokenKind::Ampersand) || check(TokenKind::Star) ||
      check(TokenKind::PlusPlus) || check(TokenKind::MinusMinus)) {
    Token opTok = advance();
    // Recursively parse unary to handle chained operators like **v or -*x
    ExprPtr operand = parseUnary();
    return std::make_shared<UnaryExprAST>(opTok.loc, opTok.lexeme, operand);
  }
  return parsePostfix();
}

ExprPtr Parser::parsePostfix() {
  ExprPtr expr = parsePrimary();

  while (true) {
    Location loc = peek().loc;

    if (match(TokenKind::Dot)) {
      std::string mName;
      if (check(TokenKind::Identifier)) {
        mName = advance().lexeme;
      } else if (check(TokenKind::IntegerLiteral)) {
        mName = advance().lexeme;
      } else {
        error(loc, "Expected field, method name, or tuple index after '.'");
      }
      expr = std::make_shared<MemberAccessExprAST>(loc, expr, mName, false);
    } else if (!m_inSwitchPattern && check(TokenKind::Arrow) &&
               peekNext().kind == TokenKind::Identifier) {
      advance();  // consume ->
      Token memberTok = consume(TokenKind::Identifier,
                                "Expected field or method name after '->'");
      expr = std::make_shared<MemberAccessExprAST>(loc, expr, memberTok.lexeme,
                                                   true);
    } else if (match(TokenKind::PlusPlus)) {
      expr = std::make_shared<UnaryExprAST>(loc, "post++", expr);
    } else if (match(TokenKind::MinusMinus)) {
      expr = std::make_shared<UnaryExprAST>(loc, "post--", expr);
    } else if (match(TokenKind::LParen)) {
      // Function call or UFCS method call
      std::vector<ExprPtr> args;
      while (!isAtEnd() && !check(TokenKind::RParen)) {
        args.push_back(parseExpression());
        if (!match(TokenKind::Comma)) break;
      }
      consume(TokenKind::RParen, "Expected ')' after call arguments");
      expr = std::make_shared<CallExprAST>(loc, expr, std::vector<TypeASTPtr>{},
                                           args);
    } else if (check(TokenKind::LBracket)) {
      if (isAttributeNext()) {
        break;
      }
      advance();  // consume '['
      // Indexing or slice indexing
      if (check(TokenKind::Colon) || check(TokenKind::DotDot)) {
        advance();  // consume ':' or '..'
        ExprPtr endE = nullptr;
        if (!check(TokenKind::RBracket)) {
          endE = parseExpression();
        }
        consume(TokenKind::RBracket, "Expected ']' after slice range");
        expr = std::make_shared<SliceExprAST>(loc, expr, nullptr, endE);
      } else {
        ExprPtr firstE = parseExpression();
        if (match(TokenKind::Colon) || match(TokenKind::DotDot)) {
          ExprPtr endE = nullptr;
          if (!check(TokenKind::RBracket)) {
            endE = parseExpression();
          }
          consume(TokenKind::RBracket, "Expected ']' after slice range");
          expr = std::make_shared<SliceExprAST>(loc, expr, firstE, endE);
        } else {
          consume(TokenKind::RBracket, "Expected ']' after index");
          expr = std::make_shared<IndexExprAST>(loc, expr, firstE);
        }
      }
    } else if (check(TokenKind::LBrace)) {
      if (auto callExpr = std::dynamic_pointer_cast<CallExprAST>(expr)) {
        ExprPtr trailing = parseBlockExpression();
        callExpr->arguments.push_back(trailing);
      } else if (isLambdaBlock()) {
        ExprPtr trailing = parseClosureExpression();
        std::vector<ExprPtr> args = {trailing};
        expr = std::make_shared<CallExprAST>(loc, expr,
                                             std::vector<TypeASTPtr>{}, args);
      } else {
        break;
      }
    } else {
      break;
    }
  }

  return expr;
}

ExprPtr Parser::parsePrimary() {
  Location loc = peek().loc;

  if (match(TokenKind::IntegerLiteral)) {
    Token tok = previous();
    ExprPtr lit = std::make_shared<IntegerLiteralExprAST>(loc, tok.lexeme);
    if (!tok.suffix.empty()) {
      auto callee = std::make_shared<IdentifierExprAST>(loc, tok.suffix);
      auto call = std::make_shared<CallExprAST>(
          loc, callee, std::vector<TypeASTPtr>{}, std::vector<ExprPtr>{lit});
      call->isUserLiteral = true;
      call->literalSuffix = tok.suffix;
      return call;
    }
    return lit;
  }
  if (match(TokenKind::FloatLiteral)) {
    Token tok = previous();
    ExprPtr lit = std::make_shared<FloatLiteralExprAST>(loc, tok.lexeme);
    if (!tok.suffix.empty()) {
      auto callee = std::make_shared<IdentifierExprAST>(loc, tok.suffix);
      auto call = std::make_shared<CallExprAST>(
          loc, callee, std::vector<TypeASTPtr>{}, std::vector<ExprPtr>{lit});
      call->isUserLiteral = true;
      call->literalSuffix = tok.suffix;
      return call;
    }
    return lit;
  }
  if (match(TokenKind::StringLiteral)) {
    Token tok = previous();
    ExprPtr lit = std::make_shared<StringLiteralExprAST>(loc, tok.lexeme);
    if (!tok.suffix.empty()) {
      auto callee = std::make_shared<IdentifierExprAST>(loc, tok.suffix);
      auto call = std::make_shared<CallExprAST>(
          loc, callee, std::vector<TypeASTPtr>{}, std::vector<ExprPtr>{lit});
      call->isUserLiteral = true;
      call->literalSuffix = tok.suffix;
      return call;
    }
    return lit;
  }
  if (match(TokenKind::CharLiteral)) {
    Token tok = previous();
    ExprPtr lit = std::make_shared<CharLiteralExprAST>(loc, tok.lexeme);
    if (!tok.suffix.empty()) {
      auto callee = std::make_shared<IdentifierExprAST>(loc, tok.suffix);
      auto call = std::make_shared<CallExprAST>(
          loc, callee, std::vector<TypeASTPtr>{}, std::vector<ExprPtr>{lit});
      call->isUserLiteral = true;
      call->literalSuffix = tok.suffix;
      return call;
    }
    return lit;
  }
  if (match(TokenKind::KwTrue))
    return std::make_shared<BoolLiteralExprAST>(loc, true);
  if (match(TokenKind::KwFalse))
    return std::make_shared<BoolLiteralExprAST>(loc, false);
  if (match(TokenKind::KwNullptr))
    return std::make_shared<NullLiteralExprAST>(loc);

  if (match(TokenKind::LBracket)) {
    if (match(TokenKind::RBracket)) {
      return std::make_shared<ArrayLiteralExprAST>(loc, std::vector<ExprPtr>{});
    }
    if (match(TokenKind::Colon)) {
      consume(TokenKind::RBracket,
              "Expected ']' after ':' in empty hashmap literal");
      return std::make_shared<MapLiteralExprAST>(
          loc, std::vector<std::pair<ExprPtr, ExprPtr>>{});
    }

    ExprPtr firstExpr = parseExpression();
    if (match(TokenKind::Colon)) {
      // Hashmap literal
      ExprPtr firstVal = parseExpression();
      std::vector<std::pair<ExprPtr, ExprPtr>> entries;
      entries.push_back({firstExpr, firstVal});
      while (match(TokenKind::Comma)) {
        if (check(TokenKind::RBracket)) break;
        ExprPtr k = parseExpression();
        consume(TokenKind::Colon, "Expected ':' after key in hashmap literal");
        ExprPtr v = parseExpression();
        entries.push_back({k, v});
      }
      consume(TokenKind::RBracket,
              "Expected ']' after hashmap literal entries");
      return std::make_shared<MapLiteralExprAST>(loc, entries);
    } else {
      // Array literal
      std::vector<ExprPtr> elements;
      elements.push_back(firstExpr);
      while (match(TokenKind::Comma)) {
        if (check(TokenKind::RBracket)) break;
        elements.push_back(parseExpression());
      }
      consume(TokenKind::RBracket, "Expected ']' after array elements");
      return std::make_shared<ArrayLiteralExprAST>(loc, elements);
    }
  }

  if (check(TokenKind::KwIf)) {
    advance();
    return parseIfExpression();
  }
  if (check(TokenKind::KwSwitch)) {
    advance();
    return parseSwitchExpression();
  }
  if (check(TokenKind::LBrace)) {
    return parseBlockExpression();
  }

  // Closures e.g. `() -> x + 5` or `(a, b) -> a + b`
  if (check(TokenKind::LParen)) {
    size_t savedPos = m_current;
    advance();  // consume '('
    // Check if closure pattern
    bool isClosure = false;
    if (check(TokenKind::RParen)) {
      if (m_current + 1 < m_tokens.size() &&
          m_tokens[m_current + 1].kind == TokenKind::Arrow) {
        isClosure = true;
      }
    } else {
      // scan until RParen to see if followed by Arrow
      size_t tempPos = m_current;
      int depth = 1;
      while (tempPos < m_tokens.size() && depth > 0) {
        if (m_tokens[tempPos].kind == TokenKind::LParen)
          depth++;
        else if (m_tokens[tempPos].kind == TokenKind::RParen)
          depth--;
        tempPos++;
      }
      if (tempPos < m_tokens.size() &&
          m_tokens[tempPos].kind == TokenKind::Arrow) {
        isClosure = true;
      }
    }

    m_current = savedPos;  // restore
    if (isClosure) {
      return parseClosureExpression();
    }

    advance();  // consume '('
    if (match(TokenKind::RParen)) {
      return std::make_shared<TupleLiteralExprAST>(loc, std::vector<ExprPtr>{});
    }
    ExprPtr expr = parseExpression();
    if (match(TokenKind::Comma)) {
      std::vector<ExprPtr> elems;
      elems.push_back(expr);
      while (!isAtEnd() && !check(TokenKind::RParen)) {
        elems.push_back(parseExpression());
        if (!match(TokenKind::Comma)) break;
      }
      consume(TokenKind::RParen, "Expected ')' after tuple elements");
      return std::make_shared<TupleLiteralExprAST>(loc, elems);
    }
    consume(TokenKind::RParen, "Expected ')' after parenthesized expression");
    return expr;
  }

  // Scoped Identifiers, Generic Calls, Struct Instantiations, Identifiers
  if (check(TokenKind::Identifier) ||
      (isPrimitiveTypeKeyword(peek().kind) &&
       peekNext().kind == TokenKind::DoubleColon)) {
    Token firstIdent = advance();

    // Check `Dirs::South`, `Foo::Bar::new()`, `Foo::Bar{0}`, or
    // `Foo::FOO_OWNED_VAR`
    if (check(TokenKind::DoubleColon)) {
      std::vector<std::string> parts;
      parts.push_back(firstIdent.lexeme);
      while (match(TokenKind::DoubleColon)) {
        if (check(TokenKind::Identifier) ||
            isPrimitiveTypeKeyword(peek().kind)) {
          Token mTok = advance();
          parts.push_back(mTok.lexeme);
        } else {
          Token mTok = consume(TokenKind::Identifier,
                               "Expected member or method name after '::'");
          parts.push_back(mTok.lexeme);
        }
      }

      // Check if struct initialization e.g. `Foo::Bar{0}`
      if (check(TokenKind::LBrace)) {
        std::string fullTypeName;
        for (size_t i = 0; i < parts.size(); ++i) {
          if (i > 0) fullTypeName += "::";
          fullTypeName += parts[i];
        }
        auto structType = std::make_shared<TypeASTNode>(loc, fullTypeName);
        return parseStructInitExpression(structType);
      }

      std::string scopeName;
      for (size_t i = 0; i < parts.size() - 1; ++i) {
        if (i > 0) scopeName += "::";
        scopeName += parts[i];
      }
      std::string memberName = parts.back();

      std::vector<TypeASTPtr> tArgs;
      if (match(TokenKind::Less)) {
        while (!isAtEnd() && !check(TokenKind::Greater)) {
          tArgs.push_back(parseType());
          if (!match(TokenKind::Comma)) break;
        }
        consume(TokenKind::Greater, "Expected '>' after template arguments");
      }

      if (match(TokenKind::LParen)) {
        std::vector<ExprPtr> args;
        while (!isAtEnd() && !check(TokenKind::RParen)) {
          args.push_back(parseExpression());
          if (!match(TokenKind::Comma)) break;
        }
        consume(TokenKind::RParen,
                "Expected ')' after arguments in static method call");
        return std::make_shared<StaticMethodCallExprAST>(
            loc, scopeName, memberName, tArgs, args);
      }

      return std::make_shared<ScopedIdentifierExprAST>(loc, scopeName,
                                                       memberName);
    }

    // Check generic function call, struct instantiation, or static method call
    // e.g. `List<int>::new()` or `add<int>(50, 100)`
    if (check(TokenKind::Less)) {
      size_t savedPos = m_current;
      size_t savedErrCount = m_errors.size();
      advance();  // consume '<'
      std::vector<TypeASTPtr> tArgs;
      bool validGen = true;
      while (!isAtEnd() && !check(TokenKind::Greater)) {
        auto t = parseType();
        if (t)
          tArgs.push_back(t);
        else {
          validGen = false;
          break;
        }
        if (!match(TokenKind::Comma)) break;
      }

      if (validGen && match(TokenKind::Greater)) {
        if (match(TokenKind::DoubleColon)) {
          // e.g. List<int>::new()
          Token memberIdent = consume(TokenKind::Identifier,
                                      "Expected static method name after '::'");

          if (match(TokenKind::Less)) {
            while (!isAtEnd() && !check(TokenKind::Greater)) {
              tArgs.push_back(parseType());
              if (!match(TokenKind::Comma)) break;
            }
            consume(TokenKind::Greater,
                    "Expected '>' after template arguments");
          }

          if (match(TokenKind::LParen)) {
            std::vector<ExprPtr> args;
            while (!isAtEnd() && !check(TokenKind::RParen)) {
              args.push_back(parseExpression());
              if (!match(TokenKind::Comma)) break;
            }
            consume(TokenKind::RParen,
                    "Expected ')' after arguments in static method call");
            return std::make_shared<StaticMethodCallExprAST>(
                loc, firstIdent.lexeme, memberIdent.lexeme, tArgs, args);
          }

          return std::make_shared<ScopedIdentifierExprAST>(
              loc, firstIdent.lexeme, memberIdent.lexeme);
        }

        if (check(TokenKind::LParen)) {
          advance();  // consume '('
          std::vector<ExprPtr> args;
          while (!isAtEnd() && !check(TokenKind::RParen)) {
            args.push_back(parseExpression());
            if (!match(TokenKind::Comma)) break;
          }
          consume(TokenKind::RParen, "Expected ')' after call arguments");
          auto identExpr =
              std::make_shared<IdentifierExprAST>(loc, firstIdent.lexeme);
          return std::make_shared<CallExprAST>(loc, identExpr, tArgs, args);
        }
        if (check(TokenKind::LBrace)) {
          // Struct instantiation e.g. List<T>{}
          auto structType =
              std::make_shared<TypeASTNode>(loc, firstIdent.lexeme);
          structType->templateArgs = tArgs;
          return parseStructInitExpression(structType);
        }
      }
      m_current = savedPos;  // restore if not generic call
      m_errors.resize(savedErrCount);
    }

    // Struct instantiation e.g. `List{ items: p, size: 0 }` or `List<T>{}`
    if (check(TokenKind::LBrace)) {
      auto structType = std::make_shared<TypeASTNode>(loc, firstIdent.lexeme);
      return parseStructInitExpression(structType);
    }

    return std::make_shared<IdentifierExprAST>(loc, firstIdent.lexeme);
  }

  error(loc, "Unexpected token in expression: " + peek().lexeme);
  advance();  // recover
  return std::make_shared<IntegerLiteralExprAST>(loc, "0");
}

ExprPtr Parser::parseIfExpression() {
  Location loc = previous().loc;  // after 'if'
  consume(TokenKind::LParen, "Expected '(' after 'if'");
  ExprPtr cond = parseExpression();
  consume(TokenKind::RParen, "Expected ')' after condition");

  ExprPtr thenB = parseExpression();
  ExprPtr elseB = nullptr;

  if (match(TokenKind::KwElse)) {
    elseB = parseExpression();
  }

  return std::make_shared<IfExprAST>(loc, cond, thenB, elseB);
}

ExprPtr Parser::parseSwitchExpression() {
  Location loc = previous().loc;  // after 'switch'
  consume(TokenKind::LParen, "Expected '(' after 'switch'");
  ExprPtr target = parseExpression();
  consume(TokenKind::RParen, "Expected ')' after switch target");

  consume(TokenKind::LBrace, "Expected '{' to start switch body");
  std::vector<SwitchCase> cases;

  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    if (match(TokenKind::KwDefault)) {
      consume(TokenKind::Arrow, "Expected '->' after 'default'");
      ExprPtr caseBody = parseExpression();
      match(TokenKind::Semicolon);
      cases.push_back({nullptr, caseBody});
    } else {
      consume(TokenKind::KwCase, "Expected 'case' in switch expression");
      bool savedInSwitch = m_inSwitchPattern;
      m_inSwitchPattern = true;
      ExprPtr pattern = parseExpression();
      m_inSwitchPattern = savedInSwitch;
      consume(TokenKind::Arrow, "Expected '->' after case pattern");
      ExprPtr caseBody = parseExpression();
      match(TokenKind::Semicolon);
      cases.push_back({pattern, caseBody});
    }
  }

  consume(TokenKind::RBrace, "Expected '}' after switch body");
  return std::make_shared<SwitchExprAST>(loc, target, cases);
}

bool Parser::isLambdaBlock() {
  if (!check(TokenKind::LBrace)) return false;
  size_t pos = m_current + 1;
  int depth = 0;
  while (pos < m_tokens.size()) {
    const auto& tok = m_tokens[pos];
    if (tok.kind == TokenKind::LParen || tok.kind == TokenKind::LBracket) {
      depth++;
    } else if (tok.kind == TokenKind::RParen ||
               tok.kind == TokenKind::RBracket) {
      if (depth > 0) depth--;
    } else if (depth == 0) {
      if (tok.kind == TokenKind::Arrow) {
        return true;
      }
      if (tok.kind == TokenKind::LBrace || tok.kind == TokenKind::RBrace ||
          tok.kind == TokenKind::Semicolon) {
        return false;
      }
    }
    pos++;
  }
  return false;
}

ExprPtr Parser::parseBlockExpression() {
  if (isLambdaBlock()) {
    return parseClosureExpression();
  }
  Location loc = peek().loc;
  consume(TokenKind::LBrace, "Expected '{' to start block expression");

  std::vector<StmtPtr> stmts;
  ExprPtr yieldValue = nullptr;
  ExprPtr lastExpr = nullptr;

  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    if (check(TokenKind::KwYield)) {
      advance();  // consume yield
      yieldValue = parseExpression();
      match(TokenKind::Semicolon);
      if (check(TokenKind::RBrace)) break;
      continue;
    }

    StmtPtr stmt = parseStatement();
    stmts.push_back(stmt);

    if (auto yStmt = std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
      yieldValue = yStmt->value;
    } else if (auto eStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
      lastExpr = eStmt->expr;
    }
  }

  consume(TokenKind::RBrace, "Expected '}' after block expression");
  return std::make_shared<BlockExprAST>(loc, stmts, yieldValue);
}

ExprPtr Parser::parseClosureExpression() {
  Location loc = peek().loc;
  consume(TokenKind::LBrace, "Expected '{' to start lambda expression");

  std::vector<ClosureParam> params;
  bool hasParen = match(TokenKind::LParen);

  while (!isAtEnd() && !check(TokenKind::Arrow) &&
         (!hasParen || !check(TokenKind::RParen))) {
    TypeASTPtr pType = nullptr;
    std::string pName;

    if (check(TokenKind::KwInt) || check(TokenKind::KwUInt) ||
        check(TokenKind::KwBool) || check(TokenKind::KwChar) ||
        check(TokenKind::KwUChar) || check(TokenKind::KwShort) ||
        check(TokenKind::KwUShort) || check(TokenKind::KwLong) ||
        check(TokenKind::KwULong) || check(TokenKind::KwFloat) ||
        check(TokenKind::KwDouble) || check(TokenKind::KwVoid)) {
      pType = parseType();
      Token nameTok =
          consume(TokenKind::Identifier, "Expected closure parameter name");
      pName = nameTok.lexeme;
    } else if (check(TokenKind::Identifier)) {
      Token firstTok = advance();
      if (check(TokenKind::Identifier)) {
        pType = std::make_shared<TypeASTNode>(firstTok.loc, firstTok.lexeme);
        Token nameTok = advance();
        pName = nameTok.lexeme;
      } else {
        pName = firstTok.lexeme;
      }
    } else {
      error(peek().loc, "Expected parameter in lambda declaration");
      advance();
    }

    params.push_back({pName, pType});
    if (!match(TokenKind::Comma)) break;
  }

  if (hasParen) {
    consume(TokenKind::RParen, "Expected ')' after closure parameters");
  }

  consume(TokenKind::Arrow, "Expected '->' in lambda expression");

  std::vector<StmtPtr> stmts;
  ExprPtr yieldValue = nullptr;
  ExprPtr lastExpr = nullptr;

  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    StmtPtr stmt = parseStatement();
    stmts.push_back(stmt);

    if (auto eStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
      lastExpr = eStmt->expr;
    }
  }

  consume(TokenKind::RBrace, "Expected '}' after lambda expression");

  if (!yieldValue && lastExpr) {
    yieldValue = lastExpr;
  }

  ExprPtr body = std::make_shared<BlockExprAST>(loc, stmts, yieldValue);
  return std::make_shared<ClosureExprAST>(loc, params, nullptr, body);
}

ExprPtr Parser::parseStructInitExpression(TypeASTPtr structType) {
  Location loc = peek().loc;
  consume(TokenKind::LBrace, "Expected '{' for struct initialization");

  std::vector<std::pair<std::string, ExprPtr>> fields;
  size_t posIdx = 0;
  while (!isAtEnd() && !check(TokenKind::RBrace)) {
    if (check(TokenKind::Identifier) && peekNext().kind == TokenKind::Colon) {
      Token fName = advance();
      advance();  // consume ':'
      ExprPtr fVal = parseExpression();
      fields.push_back({fName.lexeme, fVal});
    } else {
      ExprPtr fVal = parseExpression();
      fields.push_back({"_pos_" + std::to_string(posIdx++), fVal});
    }
    if (!match(TokenKind::Comma)) break;
  }

  consume(TokenKind::RBrace, "Expected '}' after struct initialization");
  return std::make_shared<StructInitExprAST>(loc, structType, fields);
}

std::shared_ptr<ProgramAST> Parser::parseProgram() {
  Location programLoc =
      !m_tokens.empty() ? m_tokens[0].loc : Location("unknown", 1, 1);
  auto program = std::make_shared<ProgramAST>(programLoc);

  while (!isAtEnd()) {
    if (check(TokenKind::KwImport)) {
      advance();
      program->imports.push_back(parseImport());
    } else {
      std::vector<Attribute> attributes;
      if (isAttributeNext()) {
        attributes = parseAttributes();
      }

      if (check(TokenKind::KwStruct) || check(TokenKind::KwUnion) ||
          check(TokenKind::KwEnum) || check(TokenKind::KwType)) {
        auto decl = parseDeclaration();
        if (decl && !attributes.empty()) decl->attributes = attributes;
        program->declarations.push_back(decl);
      } else {
        // Functions or top level statements / variable declarations
        size_t savedPos = m_current;
        size_t savedErrCount = m_errors.size();
        bool isFuncDecl = false;
        TypeASTPtr t = parseType();
        if (t &&
            (check(TokenKind::Identifier) || check(TokenKind::DoubleColon) ||
             isPrimitiveTypeKeyword(peek().kind))) {
          while (check(TokenKind::Identifier) ||
                 check(TokenKind::DoubleColon) ||
                 isPrimitiveTypeKeyword(peek().kind)) {
            advance();
          }
          if (check(TokenKind::LParen) || check(TokenKind::Less)) {
            isFuncDecl = true;
          }
        }
        m_current = savedPos;
        m_errors.resize(savedErrCount);

        if (isFuncDecl) {
          auto decl = parseDeclaration();
          if (decl && !attributes.empty()) decl->attributes = attributes;
          program->declarations.push_back(decl);
        } else {
          auto stmt = parseStatement();
          if (stmt && !attributes.empty()) {
            if (auto vDecl = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
              vDecl->attributes = attributes;
            }
          }
          program->topStatements.push_back(stmt);
        }
      }
    }
  }

  return program;
}

}  // namespace Glang
