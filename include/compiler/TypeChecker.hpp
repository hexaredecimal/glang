#ifndef COMPILER_TYPECHECKER_HPP
#define COMPILER_TYPECHECKER_HPP

#include "AST.hpp"
#include "Type.hpp"
#include "SymbolTable.hpp"
#include "CompilerError.hpp"
#include <vector>
#include <string>
#include <set>
#include <map>

namespace Glang {

struct TypeCheckResult {
    std::vector<Error> errors;
    std::vector<ASTNodePtr> astNodesToCodeGen;
    std::vector<std::shared_ptr<FunctionDeclAST>> instantiatedFunctions;
    std::vector<TypePtr> instantiatedTypes;

    bool hasErrors() const { return !errors.empty(); }
};

class TypeChecker {
public:
    TypeChecker();

    void registerModuleSource(const std::string& moduleName, const std::string& sourceCode);

    TypeCheckResult check(std::shared_ptr<ProgramAST> program);

    const TypeCheckResult& result() const { return m_result; }
    const std::vector<Error>& errors() const { return m_result.errors; }
    bool hasErrors() const { return !m_result.errors.empty(); }
    const SymbolTable& symbolTable() const { return m_symbolTable; }

private:
    void error(const Location& loc, const std::string& msg, const std::string& token = "");

    TypePtr resolveTypeAST(TypeASTPtr ast);

    void processImports(std::shared_ptr<ProgramAST> program);
    void registerTypes(std::shared_ptr<ProgramAST> program);
    void registerFunctions(std::shared_ptr<ProgramAST> program);
    void registerTopLevelVariables(std::shared_ptr<ProgramAST> program);

    void checkDeclaration(DeclPtr decl);
    void checkStatement(StmtPtr stmt);
    TypePtr checkExpression(ExprPtr expr);

    void checkWhileStmt(std::shared_ptr<WhileStmtAST> stmt);
    void checkDoWhileStmt(std::shared_ptr<DoWhileStmtAST> stmt);
    void checkForStmt(std::shared_ptr<ForStmtAST> stmt);

    void instantiateType(TypePtr type, const Location& loc);
    std::string instantiateFunction(std::shared_ptr<FunctionDeclAST> fDecl, const std::map<std::string, TypePtr>& bindings, const Location& loc);

    TypePtr checkArrayLiteralExpr(std::shared_ptr<ArrayLiteralExprAST> expr, TypePtr expectedType = nullptr);
    TypePtr checkMapLiteralExpr(std::shared_ptr<MapLiteralExprAST> expr, TypePtr expectedType = nullptr);
    TypePtr checkIndexExpr(std::shared_ptr<IndexExprAST> expr);
    TypePtr checkSliceExpr(std::shared_ptr<SliceExprAST> expr);
    TypePtr checkBinaryExpr(std::shared_ptr<BinaryExprAST> expr);
    TypePtr checkUnaryExpr(std::shared_ptr<UnaryExprAST> expr);
    TypePtr checkCallExpr(std::shared_ptr<CallExprAST> expr);
    TypePtr checkUserLiteralCall(std::shared_ptr<CallExprAST> expr);
    TypePtr checkMemberAccessCall(std::shared_ptr<CallExprAST> expr,
                                  std::shared_ptr<MemberAccessExprAST> memAccess);
    TypePtr checkIdentifierCall(std::shared_ptr<CallExprAST> expr,
                                std::shared_ptr<IdentifierExprAST> ident);
    TypePtr checkCallableExprCall(std::shared_ptr<CallExprAST> expr);

    struct FunctionOverloadMatch {
        Symbol* function = nullptr;
        std::map<std::string, TypePtr> bindings;
    };

    struct UfcsOverloadMatch {
        Symbol* function = nullptr;
        std::map<std::string, TypePtr> bindings;
        std::vector<ExprPtr> fullArguments;
    };

    std::map<std::string, TypePtr> collectExplicitTemplateBindings(
        std::shared_ptr<CallExprAST> expr,
        const std::shared_ptr<FunctionDeclAST>& funcAST);
    bool hasUnboundTemplateParams(
        const std::shared_ptr<FunctionDeclAST>& funcAST,
        const std::map<std::string, TypePtr>& bindings);

    FunctionOverloadMatch findBestDirectFunctionOverload(
        std::shared_ptr<CallExprAST> expr, const std::vector<Symbol*>& funcs);
    UfcsOverloadMatch findBestUfcsFunctionOverload(
        std::shared_ptr<CallExprAST> expr, TypePtr objType,
        const std::vector<Symbol*>& funcs,
        std::shared_ptr<MemberAccessExprAST> memAccess);

    std::vector<ExprPtr> buildUfcsFullArguments(
        std::shared_ptr<MemberAccessExprAST> memAccess, TypePtr objType,
        const std::vector<ExprPtr>& callArgs, TypePtr functionType);

    TypePtr resolveMatchedFunctionReturnType(
        Symbol* matchedFn, const std::map<std::string, TypePtr>& bindings);
    void setMatchedFunctionTarget(
        std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
        const std::map<std::string, TypePtr>& bindings);
    void packVariadicCallArguments(
        std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
        const std::map<std::string, TypePtr>& bindings);
    void setCallTargetParamTypes(
        std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
        const std::map<std::string, TypePtr>& bindings);
    void resolveDeferredPointerArguments(
        std::vector<ExprPtr>& arguments,
        const std::vector<TypePtr>& paramTypes,
        const std::map<std::string, TypePtr>& bindings,
        const Location& loc);
    TypePtr applyMatchedFunctionCall(
        std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
        const std::map<std::string, TypePtr>& bindings);

    TypePtr finalizeUfcsMatchedCall(
        std::shared_ptr<CallExprAST> expr, Symbol* matchedFn,
        const std::map<std::string, TypePtr>& bindings,
        const std::vector<ExprPtr>& fullArguments);

    void reportDirectCallMismatchErrors(
        std::shared_ptr<CallExprAST> expr, Symbol* fnSym,
        const std::string& functionName);
    void reportUfcsCallMismatchErrors(
        std::shared_ptr<CallExprAST> expr,
        std::shared_ptr<MemberAccessExprAST> memAccess,
        const std::vector<Symbol*>& funcs);

    TypePtr checkStaticMethodCallExpr(std::shared_ptr<StaticMethodCallExprAST> expr);
    TypePtr checkMemberAccessExpr(std::shared_ptr<MemberAccessExprAST> expr);
    TypePtr checkStructInitExpr(std::shared_ptr<StructInitExprAST> expr);
    TypePtr checkIfExpr(std::shared_ptr<IfExprAST> expr);
    TypePtr checkSwitchExpr(std::shared_ptr<SwitchExprAST> expr);
    TypePtr checkBlockExpr(std::shared_ptr<BlockExprAST> expr);
    TypePtr checkClosureExpr(std::shared_ptr<ClosureExprAST> expr);
    TypePtr checkAssignExpr(std::shared_ptr<AssignExprAST> expr);
    TypePtr checkCastExpr(std::shared_ptr<CastExprAST> expr);
    TypePtr checkTupleLiteralExpr(std::shared_ptr<TupleLiteralExprAST> expr);
    TypePtr checkNullLiteralExpr(std::shared_ptr<NullLiteralExprAST> expr);

    bool deduceTemplateArgs(TypePtr paramType, TypePtr argType, std::map<std::string, TypePtr>& bindings);

    SymbolTable m_symbolTable;
    TypeCheckResult m_result;
    TypePtr m_currentYieldType{nullptr};
    TypePtr m_currentReturnType{nullptr};
    bool m_hasReturnStmt{false};
    int m_loopDepth{0};

    // Note:  Template definitions for instantiation
    std::map<std::string, std::shared_ptr<StructDeclAST>> m_genericStructDecls;
    std::map<std::string, std::shared_ptr<UnionDeclAST>> m_genericUnionDecls;
    std::map<std::string, std::shared_ptr<FunctionDeclAST>> m_genericFuncDecls;

    // Note:  Deduplication trackers for instantiated functions/types
    std::set<std::string> m_instantiatedTypeKeys;
    std::set<std::string> m_instantiatedFuncKeys;

    // Note:  Virtual modules & import tracking
    std::map<std::string, std::string> m_virtualModuleSources;
    std::set<std::string> m_activeImports;
    std::vector<std::string> m_importStack;
    std::set<std::string> m_importedModules;
};

}  // namespace Glang

#endif
