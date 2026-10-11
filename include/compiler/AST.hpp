#ifndef COMPILER_AST_HPP
#define COMPILER_AST_HPP

#include "Location.hpp"
#include "Type.hpp"
#include <string>
#include <vector>
#include <memory>
#include <utility>

namespace Glang {

class ASTVisitor;

class ASTNode {
public:
    Location loc;
    TypePtr inferredType{nullptr};
    std::string doc;

    explicit ASTNode(Location l, std::string d = "") : loc(std::move(l)), doc(std::move(d)) {}
    virtual ~ASTNode() = default;

    virtual std::string toTreeString(int indent = 0) const = 0;
};

using ASTNodePtr = std::shared_ptr<ASTNode>;

class TypeASTNode : public ASTNode {
 public:
  std::string name;
  bool isPointer{false};
  bool isConst{false};
  bool isArray{false};
  bool isSlice{false};
  bool isMap{false};
  bool isTuple{false};
  bool isFunctionType{false};
  std::string
      declName;  // Note:  Name declared in C-style function pointer e.g. fn
  int arraySize{0};
  std::shared_ptr<TypeASTNode> pointerBase{nullptr};
  std::shared_ptr<TypeASTNode> elementType{nullptr};
  std::shared_ptr<TypeASTNode> keyType{nullptr};
  std::shared_ptr<TypeASTNode> returnType{nullptr};
  std::vector<std::shared_ptr<TypeASTNode>> templateArgs;
  std::vector<std::shared_ptr<TypeASTNode>> tupleElementTypes;
  std::vector<std::shared_ptr<TypeASTNode>> paramTypes;

  explicit TypeASTNode(Location l, std::string n = "")
      : ASTNode(std::move(l)), name(std::move(n)) {}

  std::string toTreeString(int indent = 0) const override;
};
using TypeASTPtr = std::shared_ptr<TypeASTNode>;

// Expressions
class ExprAST : public ASTNode {
public:
    explicit ExprAST(Location l) : ASTNode(std::move(l)) {}
};
using ExprPtr = std::shared_ptr<ExprAST>;

class TupleLiteralExprAST : public ExprAST {
public:
    std::vector<ExprPtr> elements;
    TupleLiteralExprAST(Location l, std::vector<ExprPtr> elems)
        : ExprAST(std::move(l)), elements(std::move(elems)) {}

    std::string toTreeString(int indent = 0) const override;
};

class ArrayLiteralExprAST : public ExprAST {
public:
    std::vector<ExprPtr> elements;
    ArrayLiteralExprAST(Location l, std::vector<ExprPtr> elems)
        : ExprAST(std::move(l)), elements(std::move(elems)) {}
    std::string toTreeString(int indent = 0) const override;
};

class MapLiteralExprAST : public ExprAST {
public:
    std::vector<std::pair<ExprPtr, ExprPtr>> entries;
    MapLiteralExprAST(Location l, std::vector<std::pair<ExprPtr, ExprPtr>> e)
        : ExprAST(std::move(l)), entries(std::move(e)) {}
    std::string toTreeString(int indent = 0) const override;
};

class IndexExprAST : public ExprAST {
public:
    ExprPtr target;
    ExprPtr index;
    IndexExprAST(Location l, ExprPtr tgt, ExprPtr idx)
        : ExprAST(std::move(l)), target(std::move(tgt)), index(std::move(idx)) {}
    std::string toTreeString(int indent = 0) const override;
};

class SliceExprAST : public ExprAST {
public:
    ExprPtr target;
    ExprPtr startExpr;  // NOTE: nullptr if omitted
    ExprPtr endExpr;    //       ^^^^^^^^^^^^^^^^^
    SliceExprAST(Location l, ExprPtr tgt, ExprPtr startE, ExprPtr endE)
        : ExprAST(std::move(l)), target(std::move(tgt)), startExpr(std::move(startE)), endExpr(std::move(endE)) {}
    std::string toTreeString(int indent = 0) const override;
};

class IntegerLiteralExprAST : public ExprAST {
public:
    std::string value;
    IntegerLiteralExprAST(Location l, std::string val) : ExprAST(std::move(l)), value(std::move(val)) {}
    std::string toTreeString(int indent = 0) const override;
};

class FloatLiteralExprAST : public ExprAST {
public:
    std::string value;
    FloatLiteralExprAST(Location l, std::string val) : ExprAST(std::move(l)), value(std::move(val)) {}
    std::string toTreeString(int indent = 0) const override;
};

class StringLiteralExprAST : public ExprAST {
public:
    std::string value;
    StringLiteralExprAST(Location l, std::string val) : ExprAST(std::move(l)), value(std::move(val)) {}
    std::string toTreeString(int indent = 0) const override;
};

class CharLiteralExprAST : public ExprAST {
public:
    std::string value;
    CharLiteralExprAST(Location l, std::string val) : ExprAST(std::move(l)), value(std::move(val)) {}
    std::string toTreeString(int indent = 0) const override;
};

class BoolLiteralExprAST : public ExprAST {
public:
    bool value;
    BoolLiteralExprAST(Location l, bool val) : ExprAST(std::move(l)), value(val) {}
    std::string toTreeString(int indent = 0) const override;
};

class NullLiteralExprAST : public ExprAST {
public:
    NullLiteralExprAST(Location l) : ExprAST(std::move(l)) {}
    std::string toTreeString(int indent = 0) const override;
};

class IdentifierExprAST : public ExprAST {
public:
    std::string name;
    IdentifierExprAST(Location l, std::string n) : ExprAST(std::move(l)), name(std::move(n)) {}
    std::string toTreeString(int indent = 0) const override;
};

class ScopedIdentifierExprAST : public ExprAST {
public:
    std::string scopeName;
    std::string memberName;
    ScopedIdentifierExprAST(Location l, std::string scope, std::string member)
        : ExprAST(std::move(l)), scopeName(std::move(scope)), memberName(std::move(member)) {}
    std::string toTreeString(int indent = 0) const override;
};

class BinaryExprAST : public ExprAST {
public:
    std::string op;
    ExprPtr left;
    ExprPtr right;
    BinaryExprAST(Location l, std::string o, ExprPtr lhs, ExprPtr rhs)
        : ExprAST(std::move(l)), op(std::move(o)), left(std::move(lhs)), right(std::move(rhs)) {}
    std::string toTreeString(int indent = 0) const override;
};

class UnaryExprAST : public ExprAST {
public:
 std::string op;  // NOTE: e.g. "&", "*", "-", "!", "sizeof"
 ExprPtr operand{nullptr};
 TypeASTPtr typeOperand{nullptr};
 UnaryExprAST(Location l, std::string o, ExprPtr opnd)
     : ExprAST(std::move(l)), op(std::move(o)), operand(std::move(opnd)) {}
 UnaryExprAST(Location l, std::string o, TypeASTPtr tOpnd)
     : ExprAST(std::move(l)), op(std::move(o)), typeOperand(std::move(tOpnd)) {}
 std::string toTreeString(int indent = 0) const override;
};

class MemberAccessExprAST : public ExprAST {
public:
    ExprPtr object;
    std::string memberName;
    bool isPointerArrow{false};
    MemberAccessExprAST(Location l, ExprPtr obj, std::string member, bool isArrow = false)
        : ExprAST(std::move(l)), object(std::move(obj)), memberName(std::move(member)), isPointerArrow(isArrow) {}
    std::string toTreeString(int indent = 0) const override;
};

class CallExprAST : public ExprAST {
public:
    ExprPtr callee;
    std::vector<TypeASTPtr> templateArgs;
    std::vector<ExprPtr> arguments;
    bool isUserLiteral{false};
    std::string literalSuffix;
    std::string targetMangledName;
    std::vector<TypePtr> targetParamTypes;
    TypePtr targetReturnType{nullptr};
    CallExprAST(Location l, ExprPtr cal, std::vector<TypeASTPtr> tArgs, std::vector<ExprPtr> args)
        : ExprAST(std::move(l)), callee(std::move(cal)), templateArgs(std::move(tArgs)), arguments(std::move(args)) {}
    std::string toTreeString(int indent = 0) const override;
};

class StaticMethodCallExprAST : public ExprAST {
public:
    std::string targetType;
    std::string methodName;
    std::vector<TypeASTPtr> templateArgs;
    std::vector<ExprPtr> arguments;
    std::string targetMangledName;
    std::vector<TypePtr> targetParamTypes;
    TypePtr targetReturnType{nullptr};
    StaticMethodCallExprAST(Location l, std::string target, std::string method, std::vector<TypeASTPtr> tArgs, std::vector<ExprPtr> args)
        : ExprAST(std::move(l)), targetType(std::move(target)), methodName(std::move(method)), templateArgs(std::move(tArgs)), arguments(std::move(args)) {}
    std::string toTreeString(int indent = 0) const override;
};

class StructInitExprAST : public ExprAST {
public:
    TypeASTPtr structType;
    std::vector<std::pair<std::string, ExprPtr>> fieldInits;
    StructInitExprAST(Location l, TypeASTPtr stType, std::vector<std::pair<std::string, ExprPtr>> fields)
        : ExprAST(std::move(l)), structType(std::move(stType)), fieldInits(std::move(fields)) {}
    std::string toTreeString(int indent = 0) const override;
};

class YieldExprAST : public ExprAST {
public:
    ExprPtr yieldedExpr;
    YieldExprAST(Location l, ExprPtr expr) : ExprAST(std::move(l)), yieldedExpr(std::move(expr)) {}
    std::string toTreeString(int indent = 0) const override;
};

class StatementAST : public ASTNode {
public:
    explicit StatementAST(Location l) : ASTNode(std::move(l)) {}
};
using StmtPtr = std::shared_ptr<StatementAST>;

class BlockExprAST : public ExprAST {
public:
    std::vector<StmtPtr> statements;
    ExprPtr yieldExpr{nullptr};
    BlockExprAST(Location l, std::vector<StmtPtr> stmts, ExprPtr yExpr = nullptr)
        : ExprAST(std::move(l)), statements(std::move(stmts)), yieldExpr(std::move(yExpr)) {}
    std::string toTreeString(int indent = 0) const override;
};

class IfExprAST : public ExprAST {
public:
    ExprPtr condition;
    ExprPtr thenBranch;
    ExprPtr elseBranch;
    IfExprAST(Location l, ExprPtr cond, ExprPtr thenB, ExprPtr elseB)
        : ExprAST(std::move(l)), condition(std::move(cond)), thenBranch(std::move(thenB)), elseBranch(std::move(elseB)) {}
    std::string toTreeString(int indent = 0) const override;
};

struct SwitchCase {
  ExprPtr pattern;  // NOTE: nullptr if default
  ExprPtr body;     // NOTE: Expr or BlockExpr
};

class SwitchExprAST : public ExprAST {
public:
    ExprPtr targetExpr;
    std::vector<SwitchCase> cases;
    SwitchExprAST(Location l, ExprPtr target, std::vector<SwitchCase> c)
        : ExprAST(std::move(l)), targetExpr(std::move(target)), cases(std::move(c)) {}
    std::string toTreeString(int indent = 0) const override;
};

struct ClosureParam {
    std::string name;
    TypeASTPtr typeAst{nullptr};
};

class ClosureExprAST : public ExprAST {
public:
    std::vector<ClosureParam> params;
    TypeASTPtr returnTypeAst{nullptr};
    ExprPtr body;  // NOTE: Shorthand expr or BlockExpr
    ClosureExprAST(Location l, std::vector<ClosureParam> p, TypeASTPtr retType, ExprPtr b)
        : ExprAST(std::move(l)), params(std::move(p)), returnTypeAst(std::move(retType)), body(std::move(b)) {}
    std::string toTreeString(int indent = 0) const override;
};

class AssignExprAST : public ExprAST {
public:
    std::string op{"="};
    ExprPtr target;
    ExprPtr value;
    AssignExprAST(Location l, ExprPtr tgt, ExprPtr val, std::string o = "=")
        : ExprAST(std::move(l)), op(std::move(o)), target(std::move(tgt)), value(std::move(val)) {}
    std::string toTreeString(int indent = 0) const override;
};

class CastExprAST : public ExprAST {
public:
    ExprPtr expr;
    TypeASTPtr targetTypeAst;
    CastExprAST(Location l, ExprPtr e, TypeASTPtr t)
        : ExprAST(std::move(l)), expr(std::move(e)), targetTypeAst(std::move(t)) {}
    std::string toTreeString(int indent = 0) const override;
};

struct AttributeArg {
  std::string
      name;  // NOTE: Key if named argument e.g. "name", empty if positional
  ExprPtr value;
};

struct Attribute {
    Location loc;
    std::string name;
    std::vector<AttributeArg> args;

    Attribute() = default;
    Attribute(Location l, std::string n, std::vector<AttributeArg> a = {})
        : loc(std::move(l)), name(std::move(n)), args(std::move(a)) {}
};

// Statements
class VarDeclStmtAST : public StatementAST {
public:
    std::vector<Attribute> attributes;
    std::string name;
    TypeASTPtr typeAst;  // NOTE: nullptr if auto
    ExprPtr initializer;
    bool isConst{false};
    bool isStatic{false};
    VarDeclStmtAST(Location l, std::string n, TypeASTPtr t, ExprPtr init, bool c = false, bool s = false)
        : StatementAST(std::move(l)), name(std::move(n)), typeAst(std::move(t)), initializer(std::move(init)), isConst(c), isStatic(s) {}
    std::string toTreeString(int indent = 0) const override;
};

class ExprStmtAST : public StatementAST {
public:
    ExprPtr expr;
    ExprStmtAST(Location l, ExprPtr e) : StatementAST(std::move(l)), expr(std::move(e)) {}
    std::string toTreeString(int indent = 0) const override;
};

class ReturnStmtAST : public StatementAST {
public:
    ExprPtr value;
    ReturnStmtAST(Location l, ExprPtr v = nullptr) : StatementAST(std::move(l)), value(std::move(v)) {}
    std::string toTreeString(int indent = 0) const override;
};

class YieldStmtAST : public StatementAST {
public:
    ExprPtr value;
    YieldStmtAST(Location l, ExprPtr v) : StatementAST(std::move(l)), value(std::move(v)) {}
    std::string toTreeString(int indent = 0) const override;
};

class BreakStmtAST : public StatementAST {
public:
    BreakStmtAST(Location l) : StatementAST(std::move(l)) {}
    std::string toTreeString(int indent = 0) const override;
};

class ContinueStmtAST : public StatementAST {
public:
    ContinueStmtAST(Location l) : StatementAST(std::move(l)) {}
    std::string toTreeString(int indent = 0) const override;
};

class DeferStmtAST : public StatementAST {
public:
    StmtPtr deferredStmt;
    DeferStmtAST(Location l, StmtPtr stmt)
        : StatementAST(std::move(l)), deferredStmt(std::move(stmt)) {}
    std::string toTreeString(int indent = 0) const override;
};

struct ImportItem {
  std::string modulePath;  // NOTE: e.g. "std.stdio"
  std::vector<std::string>
      selectiveSymbols;  // NOTE: e.g. {"writeln", "writefln"}
};

class ImportStmtAST : public StatementAST {
public:
    std::vector<ImportItem> items;
    ImportStmtAST(Location l, std::vector<ImportItem> it)
        : StatementAST(std::move(l)), items(std::move(it)) {}
    std::string toTreeString(int indent = 0) const override;
};

class WhileStmtAST : public StatementAST {
public:
    ExprPtr condition;
    StmtPtr body;
    WhileStmtAST(Location l, ExprPtr cond, StmtPtr b)
        : StatementAST(std::move(l)), condition(std::move(cond)), body(std::move(b)) {}
    std::string toTreeString(int indent = 0) const override;
};

class DoWhileStmtAST : public StatementAST {
public:
    StmtPtr body;
    ExprPtr condition;
    DoWhileStmtAST(Location l, StmtPtr b, ExprPtr cond)
        : StatementAST(std::move(l)), body(std::move(b)), condition(std::move(cond)) {}
    std::string toTreeString(int indent = 0) const override;
};

class ForStmtAST : public StatementAST {
public:
 StmtPtr init;       // NOTE: VarDecl or ExprStmt or nullptr
 ExprPtr condition;  // Note:  nullptr if omitted
 ExprPtr post;       // Note:  nullptr if omitted
 StmtPtr body;
 ForStmtAST(Location l, StmtPtr i, ExprPtr cond, ExprPtr p, StmtPtr b)
     : StatementAST(std::move(l)),
       init(std::move(i)),
       condition(std::move(cond)),
       post(std::move(p)),
       body(std::move(b)) {}
 std::string toTreeString(int indent = 0) const override;
};

// Note:  Top-Level Declarations
class DeclAST : public ASTNode {
public:
    std::vector<Attribute> attributes;
    explicit DeclAST(Location l) : ASTNode(std::move(l)) {}
};
using DeclPtr = std::shared_ptr<DeclAST>;

struct StructField {
    std::string name;
    TypeASTPtr typeAst;
    std::string doc;
};

struct EnumMember {
    std::string name;
    std::string doc;
};

class TypeAliasDeclAST;

class StructDeclAST : public DeclAST {
public:
    std::string name;
    std::vector<std::string> typeParams;  // Note:  Generics e.g. <T>
    std::vector<StructField> fields;
    std::vector<std::shared_ptr<TypeAliasDeclAST>> typeAliases;
    StructDeclAST(Location l, std::string n, std::vector<std::string> tParams,
                  std::vector<StructField> f,
                  std::vector<std::shared_ptr<TypeAliasDeclAST>> aliases = {})
        : DeclAST(std::move(l)), name(std::move(n)),
          typeParams(std::move(tParams)), fields(std::move(f)),
          typeAliases(std::move(aliases)) {}
    std::string toTreeString(int indent = 0) const override;
};

class UnionDeclAST : public DeclAST {
public:
    std::string name;
    std::vector<std::string> typeParams;
    std::vector<StructField> fields;
    UnionDeclAST(Location l, std::string n, std::vector<std::string> tParams, std::vector<StructField> f)
        : DeclAST(std::move(l)), name(std::move(n)), typeParams(std::move(tParams)), fields(std::move(f)) {}
    std::string toTreeString(int indent = 0) const override;
};

class EnumDeclAST : public DeclAST {
public:
    std::string name;
    std::vector<std::string> enumerators;
    std::vector<EnumMember> members;
    EnumDeclAST(Location l, std::string n, std::vector<std::string> enums, std::vector<EnumMember> m = {})
        : DeclAST(std::move(l)), name(std::move(n)), enumerators(std::move(enums)), members(std::move(m)) {
        if (members.empty() && !enumerators.empty()) {
            for (const auto& en : enumerators) {
                members.push_back({en, ""});
            }
        }
    }
    std::string toTreeString(int indent = 0) const override;
};

struct ParamDecl {
    std::string name;
    TypeASTPtr typeAst;
    bool isVariadic{false};
    std::string doc;
};

class FunctionDeclAST : public DeclAST {
public:
    std::string name;
    std::string mangledName;
    std::string ownerTypeName;            // Note:  e.g., "List" for List::new
    std::vector<std::string> typeParams;  // Note:  Generics e.g. <T>
    std::vector<ParamDecl> parameters;
    TypeASTPtr returnTypeAst;
    ExprPtr body;  // Note:  Either BlockExpr or shorthand expression
    bool isShorthand{false};
    Location endLoc;

    FunctionDeclAST(Location l, std::string n, std::string ownerType, std::vector<std::string> tParams,
                    std::vector<ParamDecl> params, TypeASTPtr retType, ExprPtr b, bool shorthand = false)
        : DeclAST(std::move(l)), name(std::move(n)), ownerTypeName(std::move(ownerType)),
          typeParams(std::move(tParams)), parameters(std::move(params)), returnTypeAst(std::move(retType)),
          body(std::move(b)), isShorthand(shorthand) {}
    std::string toTreeString(int indent = 0) const override;
};

class TypeAliasDeclAST : public DeclAST {
public:
    std::string aliasName;
    std::vector<std::string> typeParams;
    TypeASTPtr targetTypeAst;

    TypeAliasDeclAST(Location l, std::string name, std::vector<std::string> params, TypeASTPtr target)
        : DeclAST(std::move(l)), aliasName(std::move(name)), typeParams(std::move(params)), targetTypeAst(std::move(target)) {}

    std::string toTreeString(int indent = 0) const override;
};

class TypeAliasStmtAST : public StatementAST {
public:
    std::shared_ptr<TypeAliasDeclAST> decl;
    TypeAliasStmtAST(Location l, std::shared_ptr<TypeAliasDeclAST> d)
        : StatementAST(std::move(l)), decl(std::move(d)) {}
    std::string toTreeString(int indent = 0) const override;
};

class ProgramAST : public ASTNode {
public:
    std::vector<ImportStmtAST> imports;
    std::vector<DeclPtr> declarations;
    std::vector<StmtPtr> topStatements;  // Note:  Top-level statements if any

    explicit ProgramAST(Location l) : ASTNode(std::move(l)) {}
    std::string toTreeString(int indent = 0) const override;
};

}  // namespace Glang

#endif
