#ifndef COMPILER_CODEGEN_HPP
#define COMPILER_CODEGEN_HPP

#include "AST.hpp"
#include "Type.hpp"
#include "CompilerError.hpp"

#include <string>
#include <vector>
#include <unordered_map>
#include <set>
#include <memory>

namespace Glang {

struct ILLocal {
    int index;
    std::string name;
    std::string ilType;
    TypePtr type;
    bool isByRef;
};

struct ILMethodContext {
    std::string methodName;
    std::string returnType;
    std::vector<ILLocal> locals;
    std::unordered_map<std::string, int> localMap;
    std::unordered_map<std::string, int> paramMap;
    int labelCounter{0};
    int closureCounter{0};

    std::string allocLabel(const std::string& prefix = "IL_") {
        char buf[32];
        std::snprintf(buf, sizeof(buf), "%s%04d", prefix.c_str(), ++labelCounter);
        return std::string(buf);
    }

    int getOrAllocLocal(const std::string& name, const std::string& ilType, TypePtr type = nullptr) {
        auto it = localMap.find(name);
        if (it != localMap.end()) return it->second;
        int idx = static_cast<int>(locals.size());
        locals.push_back({idx, name, ilType, type, false});
        localMap[name] = idx;
        return idx;
    }

    int allocTempLocal(const std::string& ilType, TypePtr type = nullptr) {
        int idx = static_cast<int>(locals.size());
        std::string name = "V_" + std::to_string(idx);
        locals.push_back({idx, name, ilType, type, false});
        return idx;
    }
};

class CodeGen {
public:
    CodeGen() = default;
    ~CodeGen() = default;

    std::string generate(std::shared_ptr<ProgramAST> program);

    const std::vector<Error>& errors() const { return m_errors; }
    bool hasErrors() const { return !m_errors.empty(); }

private:
    void error(const Location& loc, const std::string& msg, const std::string& token = "");

    std::string sanitizeIdentifier(const std::string& name);
    std::string toILType(TypePtr type);
    std::string toILTypeFromAST(TypeASTPtr ast);

    std::string emitDecl(DeclPtr decl);
    std::string emitStructDecl(std::shared_ptr<StructDeclAST> decl);
    std::string emitUnionDecl(std::shared_ptr<UnionDeclAST> decl);
    std::string emitEnumDecl(std::shared_ptr<EnumDeclAST> decl);
    std::string emitFunctionDecl(std::shared_ptr<FunctionDeclAST> decl);

    std::string emitStmt(StmtPtr stmt, ILMethodContext& ctx);
    std::string emitVarDeclStmt(std::shared_ptr<VarDeclStmtAST> stmt, ILMethodContext& ctx);
    std::string emitReturnStmt(std::shared_ptr<ReturnStmtAST> stmt, ILMethodContext& ctx);
    std::string emitYieldStmt(std::shared_ptr<YieldStmtAST> stmt, ILMethodContext& ctx);
    std::string emitDeferStmt(std::shared_ptr<DeferStmtAST> stmt, ILMethodContext& ctx);
    std::string emitWhileStmt(std::shared_ptr<WhileStmtAST> stmt, ILMethodContext& ctx);
    std::string emitDoWhileStmt(std::shared_ptr<DoWhileStmtAST> stmt, ILMethodContext& ctx);
    std::string emitForStmt(std::shared_ptr<ForStmtAST> stmt, ILMethodContext& ctx);

    std::string emitExpr(ExprPtr expr, ILMethodContext& ctx);
    std::string emitIdentifierExpr(std::shared_ptr<IdentifierExprAST> expr, ILMethodContext& ctx);
    std::string emitScopedIdentifierExpr(std::shared_ptr<ScopedIdentifierExprAST> expr, ILMethodContext& ctx);
    std::string emitBinaryExpr(std::shared_ptr<BinaryExprAST> expr, ILMethodContext& ctx);
    std::string emitUnaryExpr(std::shared_ptr<UnaryExprAST> expr, ILMethodContext& ctx);
    std::string emitCallExpr(std::shared_ptr<CallExprAST> expr, ILMethodContext& ctx);
    std::string emitStaticMethodCallExpr(std::shared_ptr<StaticMethodCallExprAST> expr, ILMethodContext& ctx);
    std::string emitAssignExpr(std::shared_ptr<AssignExprAST> expr, ILMethodContext& ctx);
    std::string emitMemberAccessExpr(std::shared_ptr<MemberAccessExprAST> expr, ILMethodContext& ctx);
    std::string emitIndexExpr(std::shared_ptr<IndexExprAST> expr, ILMethodContext& ctx);
    std::string emitSliceExpr(std::shared_ptr<SliceExprAST> expr, ILMethodContext& ctx);
    std::string emitStructInitExpr(std::shared_ptr<StructInitExprAST> expr, ILMethodContext& ctx);
    std::string emitIfExpr(std::shared_ptr<IfExprAST> expr, ILMethodContext& ctx);
    std::string emitSwitchExpr(std::shared_ptr<SwitchExprAST> expr, ILMethodContext& ctx);
    std::string emitBlockExpr(std::shared_ptr<BlockExprAST> expr, ILMethodContext& ctx);
    std::string emitClosureExpr(std::shared_ptr<ClosureExprAST> expr, ILMethodContext& ctx);
    std::string emitCastExpr(std::shared_ptr<CastExprAST> expr, ILMethodContext& ctx);
    std::string emitArrayLiteralExpr(std::shared_ptr<ArrayLiteralExprAST> expr, ILMethodContext& ctx);
    std::string emitTupleLiteralExpr(std::shared_ptr<TupleLiteralExprAST> expr, ILMethodContext& ctx);
    std::string emitMapLiteralExpr(std::shared_ptr<MapLiteralExprAST> expr, ILMethodContext& ctx);

    std::vector<Error> m_errors;
    std::set<std::string> m_emittedDecls;
    std::vector<std::string> m_closureClasses;
    int m_globalClosureCount{0};

    struct StaticFieldInfo {
        std::string name;
        std::string ilType;
    };
    std::vector<StaticFieldInfo> m_staticFields;
    bool isStaticVar(const std::string& name, std::string& outIlType) const {
        for (const auto& sf : m_staticFields) {
            if (sf.name == name) {
                outIlType = sf.ilType;
                return true;
            }
        }
        return false;
    }
};

}  // namespace Glang

#endif  // Note:  COMPILER_CODEGEN_HPP
