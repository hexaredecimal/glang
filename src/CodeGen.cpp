#include "compiler/CodeGen.hpp"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <sstream>

namespace Glang {

void CodeGen::error(const Location& loc, const std::string& msg, const std::string& token) {
    m_errors.emplace_back(loc, msg, token);
}

std::string CodeGen::sanitizeIdentifier(const std::string& name) {
    if (name.empty()) return "";
    if (name == "main") return "_main";

    std::string res;
    for (size_t i = 0; i < name.size(); ++i) {
        char c = name[i];
        if (c == ':' && i + 1 < name.size() && name[i + 1] == ':') {
          res += '/';  // Note:  Nested class in IL
          i++;
        } else if (c == '<' || c == '>') {
            res += '_';
        } else if (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$' || c == '@' || c == '`') {
            res += c;
        } else {
            res += '_';
        }
    }
    if (!res.empty() && std::isdigit(static_cast<unsigned char>(res[0]))) {
        res = "_" + res;
    }
    return res;
}

std::string CodeGen::toILType(TypePtr type) {
    if (!type) return "object";

    if (type->isPrimitive()) {
        std::string n = type->name;
        if (n == "int" || n == "int32") return "int32";
        if (n == "uint" || n == "uint32") return "unsigned int32";
        if (n == "short" || n == "int16") return "int16";
        if (n == "ushort" || n == "uint16") return "unsigned int16";
        if (n == "long" || n == "int64") return "int64";
        if (n == "ulong" || n == "uint64") return "unsigned int64";
        if (n == "char" || n == "uchar" || n == "uint8") return "uint8";
        if (n == "bool") return "bool";
        if (n == "float") return "float32";
        if (n == "double") return "float64";
        if (n == "void") return "void";
        if (n == "string")
          return "uint8*";  // Note:  C-style const char* / char*
        if (n == "auto") return "int32";
        return "int32";
    }

    if (type->isPointer()) {
        return toILType(type->pointerBase) + "*";
    }

    if (type->isArray()) {
        return toILType(type->elementType) + "[]";
    }

    if (type->isSlice()) {
        return "valuetype Slice`1<" + toILType(type->elementType) + ">";
    }

    if (type->isHashMap()) {
        return "class [mscorlib]System.Collections.Generic.Dictionary`2<" + toILType(type->keyType) + ", " + toILType(type->elementType) + ">";
    }

    if (type->isTuple()) {
        std::string res = "valuetype [mscorlib]System.ValueTuple`" + std::to_string(type->tupleElementTypes.size()) + "<";
        for (size_t i = 0; i < type->tupleElementTypes.size(); ++i) {
            if (i > 0) res += ", ";
            res += toILType(type->tupleElementTypes[i]);
        }
        res += ">";
        return res;
    }

    if (type->isFunction() || type->isClosure()) {
        if (!type->returnType || type->returnType->isVoid()) {
            if (type->paramTypes.empty()) {
                return "class [mscorlib]System.Action";
            }
            std::string res = "class [mscorlib]System.Action`" + std::to_string(type->paramTypes.size()) + "<";
            for (size_t i = 0; i < type->paramTypes.size(); ++i) {
                if (i > 0) res += ", ";
                res += toILType(type->paramTypes[i]);
            }
            res += ">";
            return res;
        } else {
            std::string res = "class [mscorlib]System.Func`" + std::to_string(type->paramTypes.size() + 1) + "<";
            for (size_t i = 0; i < type->paramTypes.size(); ++i) {
                res += toILType(type->paramTypes[i]) + ", ";
            }
            res += toILType(type->returnType) + ">";
            return res;
        }
    }

    if (type->isGenericParam()) {
        return "!" + (type->name.empty() ? "0" : type->name);
    }

    if (type->isStruct() || type->isUnion()) {
        std::string sName = type->toString();
        return "valuetype " + sanitizeIdentifier(sName);
    }

    if (type->isEnum()) {
        return "valuetype " + sanitizeIdentifier(type->name);
    }

    // Note:  Default: User-defined structs/unions/enums are stack allocated
    // valuetypes
    return "valuetype " + sanitizeIdentifier(type->name.empty() ? type->toString() : type->name);
}

std::string CodeGen::toILTypeFromAST(TypeASTPtr ast) {
    if (!ast) return "object";

    if (ast->isPointer) {
        return toILTypeFromAST(ast->pointerBase) + "*";
    }
    if (ast->isArray) {
        return toILTypeFromAST(ast->elementType) + "[]";
    }
    if (ast->isSlice) {
        return "valuetype Slice`1<" + toILTypeFromAST(ast->elementType) + ">";
    }
    if (ast->isMap) {
        return "class [mscorlib]System.Collections.Generic.Dictionary`2<" + toILTypeFromAST(ast->keyType) + ", " + toILTypeFromAST(ast->elementType) + ">";
    }
    if (ast->isTuple) {
        std::string res = "valuetype [mscorlib]System.ValueTuple`" + std::to_string(ast->tupleElementTypes.size()) + "<";
        for (size_t i = 0; i < ast->tupleElementTypes.size(); ++i) {
            if (i > 0) res += ", ";
            res += toILTypeFromAST(ast->tupleElementTypes[i]);
        }
        res += ">";
        return res;
    }
    if (ast->isFunctionType) {
        if (!ast->returnType || ast->returnType->name == "void") {
            if (ast->paramTypes.empty()) return "class [mscorlib]System.Action";
            std::string res = "class [mscorlib]System.Action`" + std::to_string(ast->paramTypes.size()) + "<";
            for (size_t i = 0; i < ast->paramTypes.size(); ++i) {
                if (i > 0) res += ", ";
                res += toILTypeFromAST(ast->paramTypes[i]);
            }
            res += ">";
            return res;
        } else {
            std::string res = "class [mscorlib]System.Func`" + std::to_string(ast->paramTypes.size() + 1) + "<";
            for (size_t i = 0; i < ast->paramTypes.size(); ++i) {
                res += toILTypeFromAST(ast->paramTypes[i]) + ", ";
            }
            res += toILTypeFromAST(ast->returnType) + ">";
            return res;
        }
    }

    std::string n = ast->name;
    if (n == "int" || n == "int32") return "int32";
    if (n == "uint" || n == "uint32") return "unsigned int32";
    if (n == "short" || n == "int16") return "int16";
    if (n == "ushort" || n == "uint16") return "unsigned int16";
    if (n == "long" || n == "int64") return "int64";
    if (n == "ulong" || n == "uint64") return "unsigned int64";
    if (n == "char" || n == "uchar" || n == "uint8") return "uint8";
    if (n == "bool") return "bool";
    if (n == "float") return "float32";
    if (n == "double") return "float64";
    if (n == "void") return "void";
    if (n == "string") return "uint8*";  // Note:  C-style const char* / char*
    if (n == "auto") return "int32";

    if (!ast->templateArgs.empty()) {
        std::string sName = ast->name + "<";
        for (size_t i = 0; i < ast->templateArgs.size(); ++i) {
            if (i > 0) sName += ", ";
            sName += ast->templateArgs[i]->name;
        }
        sName += ">";
        return "valuetype " + sanitizeIdentifier(sName);
    }

    if (n.size() == 1 && std::isupper(static_cast<unsigned char>(n[0]))) {
        return "!" + n;
    }

    return "valuetype " + sanitizeIdentifier(n);
}

std::string CodeGen::emitDecl(DeclPtr decl) {
    if (!decl) return "";
    if (auto sDecl = std::dynamic_pointer_cast<StructDeclAST>(decl)) {
        return emitStructDecl(sDecl);
    }
    if (auto uDecl = std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
        return emitUnionDecl(uDecl);
    }
    if (auto eDecl = std::dynamic_pointer_cast<EnumDeclAST>(decl)) {
        return emitEnumDecl(eDecl);
    }
    if (auto fDecl = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
        return emitFunctionDecl(fDecl);
    }
    return "";
}

std::string CodeGen::emitStructDecl(std::shared_ptr<StructDeclAST> decl) {
    if (!decl) return "";
    if (!decl->typeParams.empty()) {
      return "";  // Note:  Generic template definition is not emitted; only
                  // instantiated specialized structs are emitted
    }
    std::string sName = sanitizeIdentifier(decl->name);
    if (m_emittedDecls.count(sName)) return "";
    m_emittedDecls.insert(sName);

    std::ostringstream ss;
    ss << ".class public sequential ansi sealed beforefieldinit " << sName;
    ss << "\n       extends [mscorlib]System.ValueType\n{\n";

    for (const auto& field : decl->fields) {
        ss << "    .field public " << toILTypeFromAST(field.typeAst) << " " << sanitizeIdentifier(field.name) << "\n";
    }

    ss << "}\n\n";
    return ss.str();
}

std::string CodeGen::emitUnionDecl(std::shared_ptr<UnionDeclAST> decl) {
    if (!decl) return "";
    if (!decl->typeParams.empty()) {
      return "";  // Note:  Generic template definition is not emitted; only
                  // instantiated specialized unions are emitted
    }
    std::string uName = sanitizeIdentifier(decl->name);
    if (m_emittedDecls.count(uName)) return "";
    m_emittedDecls.insert(uName);

    std::ostringstream ss;
    ss << ".class public explicit ansi sealed beforefieldinit " << uName;
    ss << "\n       extends [mscorlib]System.ValueType\n{\n";

    for (const auto& field : decl->fields) {
        ss << "    .field [0] public " << toILTypeFromAST(field.typeAst) << " " << sanitizeIdentifier(field.name) << "\n";
    }

    ss << "}\n\n";
    return ss.str();
}

std::string CodeGen::emitEnumDecl(std::shared_ptr<EnumDeclAST> decl) {
    if (!decl) return "";
    std::string eName = sanitizeIdentifier(decl->name);
    if (m_emittedDecls.count(eName)) return "";
    m_emittedDecls.insert(eName);

    std::ostringstream ss;
    ss << ".class public auto ansi sealed " << eName << "\n       extends [mscorlib]System.Enum\n{\n";
    ss << "    .field public specialname rtspecialname int32 value__\n";

    for (size_t i = 0; i < decl->enumerators.size(); ++i) {
        ss << "    .field public static literal valuetype " << eName << " "
           << sanitizeIdentifier(decl->enumerators[i]) << " = int32(" << i << ")\n";
    }

    ss << "}\n\n";
    return ss.str();
}

std::string CodeGen::emitFunctionDecl(std::shared_ptr<FunctionDeclAST> decl) {
    if (!decl) return "";
    if (!decl->typeParams.empty()) {
      return "";  // Note:  Generic template functions are not emitted directly;
                  // only monomorphized concrete instances
    }
    std::string fnName = !decl->mangledName.empty() ? decl->mangledName : (!decl->ownerTypeName.empty() ? decl->ownerTypeName + "_" + decl->name : decl->name);
    std::string sFnName = sanitizeIdentifier(fnName);
    if (m_emittedDecls.count(sFnName)) return "";
    m_emittedDecls.insert(sFnName);

    ILMethodContext ctx;
    ctx.methodName = sFnName == "main" ? "_main" : sFnName;
    ctx.returnType = decl->returnTypeAst ? toILTypeFromAST(decl->returnTypeAst) : (decl->inferredType && decl->inferredType->returnType ? toILType(decl->inferredType->returnType) : "void");

    for (size_t i = 0; i < decl->parameters.size(); ++i) {
        ctx.paramMap[decl->parameters[i].name] = static_cast<int>(i);
    }

    std::ostringstream bodySS;

    if (decl->body) {
        if (auto blockBody = std::dynamic_pointer_cast<BlockExprAST>(decl->body)) {
          bool has_return_stmt = false;
          for (const auto& stmt : blockBody->statements) {
            if (auto returnAst =
                    std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
              has_return_stmt = true;
            }
            bodySS << emitStmt(stmt, ctx);
          }

          if (!has_return_stmt && blockBody->yieldExpr) {
            bodySS << emitExpr(blockBody->yieldExpr, ctx);
            bodySS << "    ret\n";
          } else if (!has_return_stmt && ctx.returnType == "void") {
            bodySS << "    ret\n";
          } else if (!has_return_stmt) {
            bodySS << "    ldc.i4.0\n";
            bodySS << "    ret\n";
          }
        } else {
            bodySS << emitExpr(decl->body, ctx);
            if (ctx.returnType == "void") {
              bodySS << "    ret\n";
            } else {
              bodySS << "    ret\n";
            }
        }
    } else {
        bodySS << "    ret\n";
    }

    std::ostringstream ss;
    ss << "    .method public static " << ctx.returnType << " " << sFnName;
    if (!decl->typeParams.empty()) {
      ss << "<";
      for (size_t i = 0; i < decl->typeParams.size(); ++i) {
        if (i > 0) ss << ", ";
        ss << decl->typeParams[i];
      }
        ss << ">";
    }
    ss << "(";
    for (size_t i = 0; i < decl->parameters.size(); ++i) {
        if (i > 0) ss << ", ";
        ss << toILTypeFromAST(decl->parameters[i].typeAst) << " " << sanitizeIdentifier(decl->parameters[i].name);
    }
    ss << ") cil managed\n    {\n";

    ss << "        .maxstack 32\n";

    if (!ctx.locals.empty()) {
        ss << "        .locals init (\n";
        for (size_t i = 0; i < ctx.locals.size(); ++i) {
            ss << "            [" << i << "] " << ctx.locals[i].ilType << " " << ctx.locals[i].name;
            if (i + 1 < ctx.locals.size()) ss << ",\n";
            else ss << "\n";
        }
        ss << "        )\n";
    }

    ss << bodySS.str();
    ss << "    }\n\n";

    return ss.str();
}

std::string CodeGen::emitStmt(StmtPtr stmt, ILMethodContext& ctx) {
    if (!stmt) return "";
    if (auto vDecl = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
        return emitVarDeclStmt(vDecl, ctx);
    }
    if (auto eStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
        std::string res = emitExpr(eStmt->expr, ctx);
        // Note:  If expression left value on stack and is not void, pop it
        if (eStmt->expr && eStmt->expr->inferredType && !eStmt->expr->inferredType->isVoid()) {
            res += "    pop\n";
        }
        return res;
    }
    if (auto rStmt = std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
        return emitReturnStmt(rStmt, ctx);
    }
    if (auto yStmt = std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
        return emitYieldStmt(yStmt, ctx);
    }
    if (auto dStmt = std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
        return emitDeferStmt(dStmt, ctx);
    }
    if (auto wStmt = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
        return emitWhileStmt(wStmt, ctx);
    }
    if (auto dwStmt = std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
        return emitDoWhileStmt(dwStmt, ctx);
    }
    if (auto fStmt = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
        return emitForStmt(fStmt, ctx);
    }
    if (std::dynamic_pointer_cast<BreakStmtAST>(stmt)) {
        return "    br.s IL_BREAK\n";
    }
    if (std::dynamic_pointer_cast<ContinueStmtAST>(stmt)) {
        return "    br.s IL_CONTINUE\n";
    }
    return "";
}

std::string CodeGen::emitVarDeclStmt(std::shared_ptr<VarDeclStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt) return "";
    std::string ilType = (stmt->inferredType && !stmt->inferredType->isUnknown()) ? toILType(stmt->inferredType) : (stmt->typeAst ? toILTypeFromAST(stmt->typeAst) : "int32");
    std::string sName = sanitizeIdentifier(stmt->name);

    if (stmt->isStatic) {
        bool found = false;
        for (const auto& sf : m_staticFields) {
            if (sf.name == stmt->name) { found = true; break; }
        }
        if (!found) {
            m_staticFields.push_back({stmt->name, ilType});
        }
        std::ostringstream ss;
        if (stmt->initializer) {
            ss << emitExpr(stmt->initializer, ctx);
            ss << "    stsfld " << ilType << " Program::" << sName << "\n";
        }
        return ss.str();
    }

    int locIdx = ctx.getOrAllocLocal(sName, ilType, stmt->inferredType);

    std::ostringstream ss;
    if (stmt->initializer) {
      ss << emitExpr(stmt->initializer, ctx);
      ss << "    stloc." << locIdx << "\n";
    } else {
      // Note:  Zero initialize valuetype on stack
      if (ilType.rfind("valuetype ", 0) == 0) {
        ss << "    ldloca.s " << locIdx << "\n";
        ss << "    initobj " << ilType << "\n";
      } else {
        ss << "    ldc.i4.0\n";
        ss << "    stloc." << locIdx << "\n";
      }
    }
    return ss.str();
}

std::string CodeGen::emitReturnStmt(std::shared_ptr<ReturnStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt) return "    ret\n";
    std::ostringstream ss;
    if (stmt->value) {
        ss << emitExpr(stmt->value, ctx);
    }
    ss << "    ret\n";
    return ss.str();
}

std::string CodeGen::emitYieldStmt(std::shared_ptr<YieldStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt || !stmt->value) return "";
    return emitExpr(stmt->value, ctx);
}

std::string CodeGen::emitDeferStmt(std::shared_ptr<DeferStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt || !stmt->deferredStmt) return "";
    // Note:  In IL, defer can be wrapped in try/finally block or emitted at
    // exit
    std::string startLabel = ctx.allocLabel("IL_TRY_");
    std::string endLabel = ctx.allocLabel("IL_FINALLY_");
    std::string afterLabel = ctx.allocLabel("IL_END_");

    std::ostringstream ss;
    ss << "    .try\n    {\n";
    ss << "        leave.s " << afterLabel << "\n";
    ss << "    }\n    finally\n    {\n";
    ss << emitStmt(stmt->deferredStmt, ctx);
    ss << "        endfinally\n";
    ss << "    }\n";
    ss << "    " << afterLabel << ":\n";
    return ss.str();
}

std::string CodeGen::emitWhileStmt(std::shared_ptr<WhileStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt) return "";
    std::string condLabel = ctx.allocLabel("IL_COND_");
    std::string bodyLabel = ctx.allocLabel("IL_BODY_");

    std::ostringstream ss;
    ss << "    br.s " << condLabel << "\n";
    ss << "    " << bodyLabel << ":\n";
    ss << emitStmt(stmt->body, ctx);
    ss << "    " << condLabel << ":\n";
    ss << emitExpr(stmt->condition, ctx);
    ss << "    brtrue.s " << bodyLabel << "\n";
    return ss.str();
}

std::string CodeGen::emitDoWhileStmt(std::shared_ptr<DoWhileStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt) return "";
    std::string bodyLabel = ctx.allocLabel("IL_DO_");

    std::ostringstream ss;
    ss << "    " << bodyLabel << ":\n";
    ss << emitStmt(stmt->body, ctx);
    ss << emitExpr(stmt->condition, ctx);
    ss << "    brtrue.s " << bodyLabel << "\n";
    return ss.str();
}

std::string CodeGen::emitForStmt(std::shared_ptr<ForStmtAST> stmt, ILMethodContext& ctx) {
    if (!stmt) return "";
    std::string condLabel = ctx.allocLabel("IL_FOR_COND_");
    std::string bodyLabel = ctx.allocLabel("IL_FOR_BODY_");

    std::ostringstream ss;
    if (stmt->init) {
        ss << emitStmt(stmt->init, ctx);
    }
    ss << "    br.s " << condLabel << "\n";
    ss << "    " << bodyLabel << ":\n";
    if (stmt->body) {
        ss << emitStmt(stmt->body, ctx);
    }
    if (stmt->post) {
        ss << emitExpr(stmt->post, ctx);
        ss << "    pop\n";
    }
    ss << "    " << condLabel << ":\n";
    if (stmt->condition) {
        ss << emitExpr(stmt->condition, ctx);
        ss << "    brtrue.s " << bodyLabel << "\n";
    } else {
        ss << "    br.s " << bodyLabel << "\n";
    }
    return ss.str();
}

std::string CodeGen::emitExpr(ExprPtr expr, ILMethodContext& ctx) {
    if (!expr) return "";
    if (auto iLit = std::dynamic_pointer_cast<IntegerLiteralExprAST>(expr)) {
        int64_t val = 0;
        try { val = std::stoll(iLit->value); } catch (...) {}
        if (val >= -128 && val <= 127) {
            return "    ldc.i4.s " + std::to_string(val) + "\n";
        }
        return "    ldc.i4 " + std::to_string(val) + "\n";
    }
    if (auto fLit = std::dynamic_pointer_cast<FloatLiteralExprAST>(expr)) {
        return "    ldc.r4 " + fLit->value + "\n";
    }
    if (auto sLit = std::dynamic_pointer_cast<StringLiteralExprAST>(expr)) {
        return "    ldstr \"" + sLit->value + "\"\n";
    }
    if (auto cLit = std::dynamic_pointer_cast<CharLiteralExprAST>(expr)) {
        int code = (!cLit->value.empty()) ? static_cast<int>(cLit->value[0]) : 0;
        return "    ldc.i4.s " + std::to_string(code) + "\n";
    }
    if (auto bLit = std::dynamic_pointer_cast<BoolLiteralExprAST>(expr)) {
        return bLit->value ? "    ldc.i4.1\n" : "    ldc.i4.0\n";
    }
    if (std::dynamic_pointer_cast<NullLiteralExprAST>(expr)) {
        return "    ldnull\n";
    }

    if (auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr)) return emitIdentifierExpr(id, ctx);
    if (auto scopedId = std::dynamic_pointer_cast<ScopedIdentifierExprAST>(expr)) return emitScopedIdentifierExpr(scopedId, ctx);
    if (auto bin = std::dynamic_pointer_cast<BinaryExprAST>(expr)) return emitBinaryExpr(bin, ctx);
    if (auto un = std::dynamic_pointer_cast<UnaryExprAST>(expr)) return emitUnaryExpr(un, ctx);
    if (auto call = std::dynamic_pointer_cast<CallExprAST>(expr)) return emitCallExpr(call, ctx);
    if (auto staticCall = std::dynamic_pointer_cast<StaticMethodCallExprAST>(expr)) return emitStaticMethodCallExpr(staticCall, ctx);
    if (auto assign = std::dynamic_pointer_cast<AssignExprAST>(expr)) return emitAssignExpr(assign, ctx);
    if (auto mem = std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) return emitMemberAccessExpr(mem, ctx);
    if (auto idx = std::dynamic_pointer_cast<IndexExprAST>(expr)) return emitIndexExpr(idx, ctx);
    if (auto sl = std::dynamic_pointer_cast<SliceExprAST>(expr)) return emitSliceExpr(sl, ctx);
    if (auto stInit = std::dynamic_pointer_cast<StructInitExprAST>(expr)) return emitStructInitExpr(stInit, ctx);
    if (auto ifE = std::dynamic_pointer_cast<IfExprAST>(expr)) return emitIfExpr(ifE, ctx);
    if (auto swE = std::dynamic_pointer_cast<SwitchExprAST>(expr)) return emitSwitchExpr(swE, ctx);
    if (auto blkE = std::dynamic_pointer_cast<BlockExprAST>(expr)) return emitBlockExpr(blkE, ctx);
    if (auto clsE = std::dynamic_pointer_cast<ClosureExprAST>(expr)) return emitClosureExpr(clsE, ctx);
    if (auto castE = std::dynamic_pointer_cast<CastExprAST>(expr)) return emitCastExpr(castE, ctx);
    if (auto arrE = std::dynamic_pointer_cast<ArrayLiteralExprAST>(expr)) return emitArrayLiteralExpr(arrE, ctx);
    if (auto tupE = std::dynamic_pointer_cast<TupleLiteralExprAST>(expr)) return emitTupleLiteralExpr(tupE, ctx);
    if (auto mapE = std::dynamic_pointer_cast<MapLiteralExprAST>(expr)) return emitMapLiteralExpr(mapE, ctx);
    if (auto yieldE = std::dynamic_pointer_cast<YieldExprAST>(expr)) return emitExpr(yieldE->yieldedExpr, ctx);

    return "";
}

std::string CodeGen::emitIdentifierExpr(std::shared_ptr<IdentifierExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string sName = sanitizeIdentifier(expr->name);

    auto pIt = ctx.paramMap.find(expr->name);
    if (pIt != ctx.paramMap.end()) {
        return "    ldarg." + std::to_string(pIt->second) + "\n";
    }

    auto lIt = ctx.localMap.find(sName);
    if (lIt != ctx.localMap.end()) {
        return "    ldloc." + std::to_string(lIt->second) + "\n";
    }

    std::string staticIlType;
    if (isStaticVar(expr->name, staticIlType)) {
        return "    ldsfld " + staticIlType + " Program::" + sName + "\n";
    }

    // Note:  Allocate on demand if not present
    int idx = ctx.getOrAllocLocal(sName, "int32", expr->inferredType);
    return "    ldloc." + std::to_string(idx) + "\n";
}

std::string CodeGen::emitScopedIdentifierExpr(std::shared_ptr<ScopedIdentifierExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string sScope = sanitizeIdentifier(expr->scopeName);
    std::string sMem = sanitizeIdentifier(expr->memberName);

    // Note:  Static field access or enum constant
    return "    ldsfld valuetype " + sScope + " " + sScope + "::" + sMem + "\n";
}

std::string CodeGen::emitBinaryExpr(std::shared_ptr<BinaryExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    ss << emitExpr(expr->left, ctx);
    ss << emitExpr(expr->right, ctx);

    std::string op = expr->op;
    if (op == "+") ss << "    add\n";
    else if (op == "-") ss << "    sub\n";
    else if (op == "*") ss << "    mul\n";
    else if (op == "/") ss << "    div\n";
    else if (op == "%") ss << "    rem\n";
    else if (op == "&") ss << "    and\n";
    else if (op == "|") ss << "    or\n";
    else if (op == "^") ss << "    xor\n";
    else if (op == "<<") ss << "    shl\n";
    else if (op == ">>") ss << "    shr\n";
    else if (op == "==") ss << "    ceq\n";
    else if (op == "!=") {
        ss << "    ceq\n";
        ss << "    ldc.i4.0\n";
        ss << "    ceq\n";
    }
    else if (op == "<") ss << "    clt\n";
    else if (op == ">") ss << "    cgt\n";
    else if (op == "<=") {
        ss << "    cgt\n";
        ss << "    ldc.i4.0\n";
        ss << "    ceq\n";
    }
    else if (op == ">=") {
        ss << "    clt\n";
        ss << "    ldc.i4.0\n";
        ss << "    ceq\n";
    }
    else {
        ss << "    add\n";
    }

    return ss.str();
}

std::string CodeGen::emitUnaryExpr(std::shared_ptr<UnaryExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    if (expr->op == "sizeof") {
        std::string targetType = "int32";
        if (expr->typeOperand) {
            targetType = toILTypeFromAST(expr->typeOperand);
        } else if (expr->operand && expr->operand->inferredType) {
            targetType = toILType(expr->operand->inferredType);
        }
        ss << "    sizeof " << targetType << "\n";
        ss << "    conv.u8\n";
        return ss.str();
    }

    if (expr->op == "&") {
        if (auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr->operand)) {
            auto pIt = ctx.paramMap.find(id->name);
            if (pIt != ctx.paramMap.end()) {
                ss << "    ldarga.s " << pIt->second << "\n";
                return ss.str();
            }
            int idx = ctx.getOrAllocLocal(sanitizeIdentifier(id->name), "int32", expr->operand->inferredType);
            ss << "    ldloca.s " << idx << "\n";
            return ss.str();
        }
    }

    if (expr->op == "*") {
        ss << emitExpr(expr->operand, ctx);
        std::string elemType = (expr->inferredType) ? toILType(expr->inferredType) : "int32";
        if (elemType == "int32") ss << "    ldind.i4\n";
        else if (elemType == "float32") ss << "    ldind.r4\n";
        else if (elemType == "float64") ss << "    ldind.r8\n";
        else ss << "    ldobj " << elemType << "\n";
        return ss.str();
    }

    ss << emitExpr(expr->operand, ctx);
    if (expr->op == "-") {
        ss << "    neg\n";
    } else if (expr->op == "!") {
        ss << "    ldc.i4.0\n";
        ss << "    ceq\n";
    } else if (expr->op == "~") {
        ss << "    not\n";
    }
    return ss.str();
}

std::string CodeGen::emitCallExpr(std::shared_ptr<CallExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;

    for (size_t i = 0; i < expr->arguments.size(); ++i) {
      ss << emitExpr(expr->arguments[i], ctx);
    }

    std::string calleeName;
    if (!expr->targetMangledName.empty()) {
        calleeName = sanitizeIdentifier(expr->targetMangledName);
    } else if (auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr->callee)) {
        calleeName = sanitizeIdentifier(id->name);
    } else {
        calleeName = "anonymous_call";
    }

    std::string retType = (expr->inferredType) ? toILType(expr->inferredType) : "void";
    if (calleeName == "print" || calleeName == "println" || calleeName == "writeln") {
        ss << "    call void [mscorlib]System.Console::WriteLine()\n";
        return ss.str();
    }

    ss << "    call " << retType << " Program::" << calleeName << "(";
    for (size_t i = 0; i < expr->arguments.size(); ++i) {
        if (i > 0) ss << ", ";
        std::string argType = (expr->arguments[i]->inferredType) ? toILType(expr->arguments[i]->inferredType) : "int32";
        ss << argType;
    }
    ss << ")\n";

    return ss.str();
}

std::string CodeGen::emitStaticMethodCallExpr(std::shared_ptr<StaticMethodCallExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;

    for (size_t i = 0; i < expr->arguments.size(); ++i) {
        ss << emitExpr(expr->arguments[i], ctx);
    }

    std::string targetClass = sanitizeIdentifier(expr->targetType);
    std::string methodName = sanitizeIdentifier(expr->methodName);
    std::string retType = (expr->inferredType) ? toILType(expr->inferredType) : "void";

    ss << "    call " << retType << " Program::" << targetClass << "_" << methodName << "(";
    for (size_t i = 0; i < expr->arguments.size(); ++i) {
        if (i > 0) ss << ", ";
        std::string argType = (expr->arguments[i]->inferredType) ? toILType(expr->arguments[i]->inferredType) : "int32";
        ss << argType;
    }
    ss << ")\n";

    return ss.str();
}

std::string CodeGen::emitAssignExpr(std::shared_ptr<AssignExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;

    if (auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr->target)) {
        ss << emitExpr(expr->value, ctx);
        std::string sName = sanitizeIdentifier(id->name);
        auto pIt = ctx.paramMap.find(id->name);
        if (pIt != ctx.paramMap.end()) {
            ss << "    starg." << pIt->second << "\n";
            return ss.str();
        }
        std::string staticIlType;
        if (isStaticVar(id->name, staticIlType)) {
            ss << "    stsfld " << staticIlType << " Program::" << sName << "\n";
            return ss.str();
        }
        int idx = ctx.getOrAllocLocal(sName, "int32", expr->value->inferredType);
        ss << "    stloc." << idx << "\n";
        return ss.str();
    }

    if (auto mem = std::dynamic_pointer_cast<MemberAccessExprAST>(expr->target)) {
      // Note:  Load object address
      if (auto objId =
              std::dynamic_pointer_cast<IdentifierExprAST>(mem->object)) {
        int locIdx = ctx.getOrAllocLocal(sanitizeIdentifier(objId->name),
                                         "valuetype Vector3");
        ss << "    ldloca.s " << locIdx << "\n";
      } else {
        ss << emitExpr(mem->object, ctx);
      }
        ss << emitExpr(expr->value, ctx);
        std::string structType = (mem->object->inferredType) ? toILType(mem->object->inferredType) : "valuetype Vector3";
        std::string fieldType = (expr->value->inferredType) ? toILType(expr->value->inferredType) : "int32";
        ss << "    stfld " << fieldType << " " << structType << "::" << sanitizeIdentifier(mem->memberName) << "\n";
        return ss.str();
    }

    ss << emitExpr(expr->value, ctx);
    return ss.str();
}

std::string CodeGen::emitMemberAccessExpr(std::shared_ptr<MemberAccessExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;

    if (expr->memberName == "length") {
        if (expr->object->inferredType && expr->object->inferredType->isArray()) {
            ss << emitExpr(expr->object, ctx);
            ss << "    ldlen\n";
            ss << "    conv.u8\n";
            return ss.str();
        }
        if (expr->object->inferredType && expr->object->inferredType->isSlice()) {
            if (auto objId = std::dynamic_pointer_cast<IdentifierExprAST>(expr->object)) {
                int locIdx = ctx.getOrAllocLocal(sanitizeIdentifier(objId->name), "valuetype Slice`1<int32>");
                ss << "    ldloca.s " << locIdx << "\n";
            } else {
                ss << emitExpr(expr->object, ctx);
            }
            ss << "    ldfld unsigned int64 valuetype Slice`1<int32>::length\n";
            return ss.str();
        }
    }

    // Note:  Tuple index access (e.g. t.0, t.1)
    bool isNumeric = !expr->memberName.empty() && std::all_of(expr->memberName.begin(), expr->memberName.end(), [](unsigned char c) { return std::isdigit(c); });
    if (isNumeric || (expr->object->inferredType && expr->object->inferredType->isTuple())) {
        int elemIdx = std::stoi(expr->memberName) + 1;
        if (auto objId = std::dynamic_pointer_cast<IdentifierExprAST>(expr->object)) {
            int locIdx = ctx.getOrAllocLocal(sanitizeIdentifier(objId->name), "valuetype [mscorlib]System.ValueTuple");
            ss << "    ldloca.s " << locIdx << "\n";
        } else {
            ss << emitExpr(expr->object, ctx);
        }
        std::string tupleType = (expr->object->inferredType) ? toILType(expr->object->inferredType) : "valuetype [mscorlib]System.ValueTuple";
        std::string fieldType = (expr->inferredType) ? toILType(expr->inferredType) : "int32";
        ss << "    ldfld " << fieldType << " " << tupleType << "::Item" << elemIdx << "\n";
        return ss.str();
    }

    if (auto objId = std::dynamic_pointer_cast<IdentifierExprAST>(expr->object)) {
        std::string objType = (expr->object->inferredType) ? toILType(expr->object->inferredType) : "valuetype Vector3";
        int locIdx = ctx.getOrAllocLocal(sanitizeIdentifier(objId->name), objType);
        ss << "    ldloca.s " << locIdx << "\n";
    } else {
        ss << emitExpr(expr->object, ctx);
    }
    std::string structType = (expr->object->inferredType) ? toILType(expr->object->inferredType) : "valuetype Vector3";
    std::string fieldType = (expr->inferredType) ? toILType(expr->inferredType) : "int32";
    ss << "    ldfld " << fieldType << " " << structType << "::" << sanitizeIdentifier(expr->memberName) << "\n";
    return ss.str();
}

std::string CodeGen::emitIndexExpr(std::shared_ptr<IndexExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    ss << emitExpr(expr->target, ctx);
    ss << emitExpr(expr->index, ctx);

    std::string elemType = (expr->inferredType) ? toILType(expr->inferredType) : "int32";
    if (elemType == "int32") ss << "    ldelem.i4\n";
    else if (elemType == "float32") ss << "    ldelem.r4\n";
    else if (elemType == "float64") ss << "    ldelem.r8\n";
    else ss << "    ldelem " << elemType << "\n";

    return ss.str();
}

std::string CodeGen::emitSliceExpr(std::shared_ptr<SliceExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    int sliceLocal = ctx.allocTempLocal("valuetype Slice`1<int32>");

    ss << "    ldloca.s " << sliceLocal << "\n";
    ss << "    initobj valuetype Slice`1<int32>\n";

    // Note:  Set ptr and len
    ss << "    ldloca.s " << sliceLocal << "\n";
    ss << emitExpr(expr->target, ctx);
    if (expr->startExpr) {
        ss << emitExpr(expr->startExpr, ctx);
        ss << "    ldelema int32\n";
    } else {
        ss << "    ldc.i4.0\n";
        ss << "    ldelema int32\n";
    }
    ss << "    stfld !0* valuetype Slice`1<int32>::ptr\n";

    ss << "    ldloca.s " << sliceLocal << "\n";
    if (expr->endExpr && expr->startExpr) {
        ss << emitExpr(expr->endExpr, ctx);
        ss << emitExpr(expr->startExpr, ctx);
        ss << "    sub\n";
        ss << "    conv.u8\n";
    } else {
        ss << "    ldc.i8 3\n";
    }
    ss << "    stfld unsigned int64 valuetype Slice`1<int32>::length\n";

    ss << "    ldloc." << sliceLocal << "\n";
    return ss.str();
}

std::string CodeGen::emitStructInitExpr(std::shared_ptr<StructInitExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string structType = (expr->inferredType && !expr->inferredType->isUnknown()) ? toILType(expr->inferredType) : toILTypeFromAST(expr->structType);
    int tempLocal = ctx.allocTempLocal(structType);

    std::ostringstream ss;
    ss << "    ldloca.s " << tempLocal << "\n";
    ss << "    initobj " << structType << "\n";

    for (size_t i = 0; i < expr->fieldInits.size(); ++i) {
        ss << "    ldloca.s " << tempLocal << "\n";
        ss << emitExpr(expr->fieldInits[i].second, ctx);
        std::string fieldName = expr->fieldInits[i].first;
        if (fieldName.rfind("_pos_", 0) == 0) {
            size_t posIdx = std::stoul(fieldName.substr(5));
            if (expr->inferredType && expr->inferredType->isStruct() && posIdx < expr->inferredType->fields.size()) {
                fieldName = expr->inferredType->fields[posIdx].name;
            }
        }
        if (fieldName.empty()) {
            fieldName = "field_" + std::to_string(i);
        }
        fieldName = sanitizeIdentifier(fieldName);
        std::string fieldType = (expr->fieldInits[i].second->inferredType) ? toILType(expr->fieldInits[i].second->inferredType) : "int32";
        ss << "    stfld " << fieldType << " " << structType << "::" << fieldName << "\n";
    }

    ss << "    ldloc." << tempLocal << "\n";
    return ss.str();
}

std::string CodeGen::emitIfExpr(std::shared_ptr<IfExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string elseLabel = ctx.allocLabel("IL_ELSE_");
    std::string endLabel = ctx.allocLabel("IL_IF_END_");

    std::ostringstream ss;
    ss << emitExpr(expr->condition, ctx);
    ss << "    brfalse.s " << elseLabel << "\n";
    ss << emitExpr(expr->thenBranch, ctx);
    ss << "    br.s " << endLabel << "\n";
    ss << "    " << elseLabel << ":\n";
    if (expr->elseBranch) {
        ss << emitExpr(expr->elseBranch, ctx);
    }
    ss << "    " << endLabel << ":\n";
    return ss.str();
}

std::string CodeGen::emitSwitchExpr(std::shared_ptr<SwitchExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string endLabel = ctx.allocLabel("IL_SWITCH_END_");
    std::vector<std::string> caseLabels;
    for (size_t i = 0; i < expr->cases.size(); ++i) {
        caseLabels.push_back(ctx.allocLabel("IL_CASE_"));
    }

    std::ostringstream ss;
    int targetLocal = ctx.allocTempLocal("int32");
    ss << emitExpr(expr->targetExpr, ctx);
    ss << "    stloc." << targetLocal << "\n";

    for (size_t i = 0; i < expr->cases.size(); ++i) {
        if (expr->cases[i].pattern) {
            ss << "    ldloc." << targetLocal << "\n";
            ss << emitExpr(expr->cases[i].pattern, ctx);
            ss << "    ceq\n";
            ss << "    brtrue.s " << caseLabels[i] << "\n";
        } else {
            ss << "    br.s " << caseLabels[i] << "\n";
        }
    }

    for (size_t i = 0; i < expr->cases.size(); ++i) {
        ss << "    " << caseLabels[i] << ":\n";
        ss << emitExpr(expr->cases[i].body, ctx);
        ss << "    br.s " << endLabel << "\n";
    }

    ss << "    " << endLabel << ":\n";
    return ss.str();
}

std::string CodeGen::emitBlockExpr(std::shared_ptr<BlockExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    for (const auto& stmt : expr->statements) {
        ss << emitStmt(stmt, ctx);
    }
    if (expr->yieldExpr) {
        ss << emitExpr(expr->yieldExpr, ctx);
    }
    return ss.str();
}

std::string CodeGen::emitClosureExpr(std::shared_ptr<ClosureExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    // Note:  Generate a display class on heap to solve capture memory safety
    int clsId = ++m_globalClosureCount;
    std::string clsName = "'<>c__DisplayClass_" + std::to_string(clsId) + "'";
    std::string retType = expr->returnTypeAst ? toILTypeFromAST(expr->returnTypeAst) : (expr->inferredType && expr->inferredType->returnType ? toILType(expr->inferredType->returnType) : "int32");

    std::ostringstream clsSS;
    clsSS << ".class nested private auto ansi beforefieldinit " << clsName << "\n";
    clsSS << "       extends [mscorlib]System.Object\n{\n";

    // Note:  Detect captured locals
    std::vector<std::pair<std::string, std::string>> captured;
    for (const auto& loc : ctx.locals) {
        captured.push_back({loc.name, loc.ilType});
        clsSS << "    .field public " << loc.ilType << " " << loc.name << "\n";
    }

    // Note:  Parameterless Constructor
    clsSS << "    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed\n    {\n";
    clsSS << "        ldarg.0\n";
    clsSS << "        call instance void [mscorlib]System.Object::.ctor()\n";
    clsSS << "        ret\n";
    clsSS << "    }\n\n";

    // Note:  Lambda body method
    clsSS << "    .method public hidebysig instance " << retType << " '<lambda_method>'(";
    for (size_t i = 0; i < expr->params.size(); ++i) {
        if (i > 0) clsSS << ", ";
        std::string pType = expr->params[i].typeAst ? toILTypeFromAST(expr->params[i].typeAst) : "int32";
        clsSS << pType << " " << sanitizeIdentifier(expr->params[i].name);
    }
    clsSS << ") cil managed\n    {\n";
    clsSS << "        .maxstack 8\n";

    ILMethodContext lambdaCtx;
    for (size_t i = 0; i < expr->params.size(); ++i) {
      lambdaCtx.paramMap[expr->params[i].name] =
          static_cast<int>(i + 1);  // Note:  arg 0 is this
    }
    clsSS << emitExpr(expr->body, lambdaCtx);
    clsSS << "        ret\n";
    clsSS << "    }\n";
    clsSS << "}\n\n";

    m_closureClasses.push_back(clsSS.str());

    std::ostringstream ss;
    int envLocal = ctx.allocTempLocal("class Program/" + clsName);
    ss << "    newobj instance void Program/" << clsName << "::.ctor()\n";
    ss << "    stloc." << envLocal << "\n";

    // Note:  Store captured local variables to closure object
    for (const auto& cap : captured) {
        auto lIt = ctx.localMap.find(cap.first);
        if (lIt != ctx.localMap.end()) {
            ss << "    ldloc." << envLocal << "\n";
            ss << "    ldloc." << lIt->second << "\n";
            ss << "    stfld " << cap.second << " Program/" << clsName << "::" << cap.first << "\n";
        }
    }

    // Note:  Load delegate
    std::string delegateType = (expr->inferredType) ? toILType(expr->inferredType) : "class [mscorlib]System.Func`1<int32>";
    ss << "    ldloc." << envLocal << "\n";
    ss << "    ldftn instance " << retType << " Program/" << clsName << "::'<lambda_method>'(";
    for (size_t i = 0; i < expr->params.size(); ++i) {
        if (i > 0) ss << ", ";
        std::string pType = expr->params[i].typeAst ? toILTypeFromAST(expr->params[i].typeAst) : "int32";
        ss << pType;
    }
    ss << ")\n";
    ss << "    newobj instance void " << delegateType << "::.ctor(object, native int)\n";

    return ss.str();
}

std::string CodeGen::emitCastExpr(std::shared_ptr<CastExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    ss << emitExpr(expr->expr, ctx);

    std::string target = toILTypeFromAST(expr->targetTypeAst);
    if (target == "float32") ss << "    conv.r4\n";
    else if (target == "float64") ss << "    conv.r8\n";
    else if (target == "int32") ss << "    conv.i4\n";
    else if (target == "unsigned int32") ss << "    conv.u4\n";
    else if (target == "int64") ss << "    conv.i8\n";
    else if (target == "unsigned int64") ss << "    conv.u8\n";
    else if (target == "uint8") ss << "    conv.u1\n";

    return ss.str();
}

std::string CodeGen::emitArrayLiteralExpr(std::shared_ptr<ArrayLiteralExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::ostringstream ss;
    std::string elemType = (expr->inferredType && expr->inferredType->elementType) ? toILType(expr->inferredType->elementType) : "int32";

    ss << "    ldc.i4 " << expr->elements.size() << "\n";
    ss << "    newarr " << elemType << "\n";

    for (size_t i = 0; i < expr->elements.size(); ++i) {
        ss << "    dup\n";
        ss << "    ldc.i4 " << i << "\n";
        ss << emitExpr(expr->elements[i], ctx);
        if (elemType == "int32") ss << "    stelem.i4\n";
        else if (elemType == "float32") ss << "    stelem.r4\n";
        else if (elemType == "float64") ss << "    stelem.r8\n";
        else ss << "    stelem " << elemType << "\n";
    }

    return ss.str();
}

std::string CodeGen::emitTupleLiteralExpr(std::shared_ptr<TupleLiteralExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string tupleType = (expr->inferredType) ? toILType(expr->inferredType) : ("valuetype [mscorlib]System.ValueTuple`" + std::to_string(expr->elements.size()));
    int tupleLocal = ctx.allocTempLocal(tupleType);

    std::ostringstream ss;
    ss << "    ldloca.s " << tupleLocal << "\n";
    ss << "    initobj " << tupleType << "\n";

    for (size_t i = 0; i < expr->elements.size(); ++i) {
        ss << "    ldloca.s " << tupleLocal << "\n";
        ss << emitExpr(expr->elements[i], ctx);
        std::string elemType = (expr->elements[i]->inferredType) ? toILType(expr->elements[i]->inferredType) : "int32";
        ss << "    stfld " << elemType << " " << tupleType << "::Item" << (i + 1) << "\n";
    }

    ss << "    ldloc." << tupleLocal << "\n";
    return ss.str();
}

std::string CodeGen::emitMapLiteralExpr(std::shared_ptr<MapLiteralExprAST> expr, ILMethodContext& ctx) {
    if (!expr) return "";
    std::string keyType = (expr->inferredType && expr->inferredType->keyType) ? toILType(expr->inferredType->keyType) : "string";
    std::string valType = (expr->inferredType && expr->inferredType->elementType) ? toILType(expr->inferredType->elementType) : "int32";
    std::string mapType = "class [mscorlib]System.Collections.Generic.Dictionary`2<" + keyType + ", " + valType + ">";

    std::ostringstream ss;
    ss << "    newobj instance void " << mapType << "::.ctor()\n";
    for (size_t i = 0; i < expr->entries.size(); ++i) {
        ss << "    dup\n";
        ss << emitExpr(expr->entries[i].first, ctx);
        ss << emitExpr(expr->entries[i].second, ctx);
        ss << "    call instance void " << mapType << "::Add(" << keyType << ", " << valType << ")\n";
    }
    return ss.str();
}

std::string CodeGen::generate(std::shared_ptr<ProgramAST> program) {
    m_errors.clear();
    m_emittedDecls.clear();
    m_closureClasses.clear();
    m_globalClosureCount = 0;

    std::ostringstream out;

    out << ".assembly 'Main' {}\n";
    out << ".module Main.exe \n";

    // Note:  Standard runtime ValueType for Slices
    out << "// Note:  --- Runtime Slice<T> Definition ---\n";
    out << ".class Slice`1<T>\n";
    out << "       extends [mscorlib]System.ValueType\n";
    out << "{\n";
    out << "    .field public !0* ptr\n";
    out << "    .field public unsigned int64 length\n";
    out << "}\n\n";

    if (!program) return out.str();

    std::vector<std::shared_ptr<StructDeclAST>> structs;
    std::vector<std::shared_ptr<UnionDeclAST>> unions;
    std::vector<std::shared_ptr<EnumDeclAST>> enums;
    std::vector<std::shared_ptr<FunctionDeclAST>> functions;

    for (const auto& decl : program->declarations) {
        if (!decl) continue;
        if (auto s = std::dynamic_pointer_cast<StructDeclAST>(decl)) structs.push_back(s);
        else if (auto u = std::dynamic_pointer_cast<UnionDeclAST>(decl)) unions.push_back(u);
        else if (auto e = std::dynamic_pointer_cast<EnumDeclAST>(decl)) enums.push_back(e);
        else if (auto f = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) functions.push_back(f);
    }

    for (const auto& e : enums) out << emitEnumDecl(e);
    for (const auto& s : structs) out << emitStructDecl(s);
    for (const auto& u : unions) out << emitUnionDecl(u);

    out << "// Note:  --- Main Program Module & Methods ---\n";
    out << ".class Program\n";
    out << "       extends [mscorlib]System.Object\n";
    out << "{\n";

    // Note:  Collect functions
    std::ostringstream methodsSS;

    for (const auto& stmt : program->topStatements) {
      if (auto vDecl = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
        if (vDecl->isStatic) {
          std::string ilType =
              (vDecl->inferredType && !vDecl->inferredType->isUnknown())
                  ? toILType(vDecl->inferredType)
                  : (vDecl->typeAst ? toILTypeFromAST(vDecl->typeAst)
                                    : "int32");
          bool found = false;
          for (const auto& sf : m_staticFields) {
            if (sf.name == vDecl->name) {
              found = true;
              break;
            }
          }
          if (!found) {
            m_staticFields.push_back({vDecl->name, ilType});
          }
        }
      }
    }

    std::string main_ret = "";
    for (const auto& f : functions) {
      if (!f) continue;
      std::string fnName =
          !f->mangledName.empty()
              ? f->mangledName
              : (!f->ownerTypeName.empty() ? f->ownerTypeName + "_" + f->name
                                           : f->name);
      std::string sFnName = sanitizeIdentifier(fnName);
      if (sFnName == "_main") {
        main_ret = f->returnTypeAst
                       ? toILTypeFromAST(f->returnTypeAst)
                       : (f->inferredType && f->inferredType->returnType
                              ? toILType(f->inferredType->returnType)
                              : "void");
        ;
      }
      methodsSS << emitFunctionDecl(f);
    }

    methodsSS << "  .method public static int32 main() cil managed {\n";
    methodsSS << "      .maxstack 32\n";
    methodsSS << "      .entrypoint\n";

    if (!main_ret.empty()) {
      methodsSS << "        call " << main_ret << " Program::_main()\n";
      methodsSS << "        ldc.i4.0\n";
      methodsSS << "        ret\n";
    } else {
      methodsSS << "        ldc.i4.0\n";
      methodsSS << "        ret\n";
    }
    methodsSS << "  }\n";
    for (const auto& cls : m_closureClasses) {
      out << cls;
    }

    for (const auto& sf : m_staticFields) {
        out << "    .field public static " << sf.ilType << " " << sanitizeIdentifier(sf.name) << "\n";
    }
    if (!m_staticFields.empty()) {
        out << "\n";
    }

    out << methodsSS.str();
    out << "}\n";

    return out.str();
}

}  // namespace Glang
