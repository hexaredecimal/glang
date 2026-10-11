#include "compiler/AST.hpp"
#include <functional>

namespace Glang {

static std::string makeIndent(int indent) {
    return std::string(indent * 2, ' ');
}

static std::string typeAnnot(const TypePtr& type) {
    if (!type) return "";
    return " : " + type->toString();
}

std::string TypeASTNode::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "Type(" + (isConst ? "const " : "") + name;
    if (isPointer && pointerBase) {
        res += "*) -> " + pointerBase->toTreeString(0);
    } else {
        res += ")";
    }
    if (!templateArgs.empty()) {
        std::function<std::string(const std::shared_ptr<TypeASTNode>&)> buildName =
            [&](const std::shared_ptr<TypeASTNode>& t) -> std::string {
          if (!t) return "";
          std::string s = t->name;
          if (!t->templateArgs.empty()) {
            s += "<";
            for (size_t i = 0; i < t->templateArgs.size(); ++i) {
              if (i > 0) s += ", ";
              s += buildName(t->templateArgs[i]);
            }
            s += ">";
          }
          if (t->isPointer) s += "*";
          return s;
        };
        res += " <";
        for (size_t i = 0; i < templateArgs.size(); ++i) {
            if (i > 0) res += ", ";
            res += buildName(templateArgs[i]);
        }
        res += ">";
    }
    return res;
}

std::string TupleLiteralExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "TupleLiteral" + typeAnnot(inferredType);
    for (const auto& elem : elements) {
        res += "\n" + (elem ? elem->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>");
    }
    return res;
}

std::string ArrayLiteralExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "ArrayLiteral" + typeAnnot(inferredType);
    for (const auto& elem : elements) {
        res += "\n" + (elem ? elem->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>");
    }
    return res;
}

std::string MapLiteralExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "MapLiteral" + typeAnnot(inferredType);
    for (const auto& entry : entries) {
        res += "\n" + makeIndent(indent + 1) + "Key:\n" + (entry.first ? entry.first->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
        res += "\n" + makeIndent(indent + 1) + "Value:\n" + (entry.second ? entry.second->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    }
    return res;
}

std::string IndexExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "IndexExpr" + typeAnnot(inferredType) + "\n";
    res += makeIndent(indent + 1) + "Target:\n" + (target ? target->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>") + "\n";
    res += makeIndent(indent + 1) + "Index:\n" + (index ? index->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    return res;
}

std::string SliceExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "SliceExpr" + typeAnnot(inferredType) + "\n";
    res += makeIndent(indent + 1) + "Target:\n" + (target ? target->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    if (startExpr) {
        res += "\n" + makeIndent(indent + 1) + "Start:\n" + startExpr->toTreeString(indent + 2);
    }
    if (endExpr) {
        res += "\n" + makeIndent(indent + 1) + "End:\n" + endExpr->toTreeString(indent + 2);
    }
    return res;
}

std::string IntegerLiteralExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "IntLiteral(" + value + ")" + typeAnnot(inferredType);
}

std::string FloatLiteralExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "FloatLiteral(" + value + ")" + typeAnnot(inferredType);
}

std::string StringLiteralExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "StringLiteral(\"" + value + "\")" + typeAnnot(inferredType);
}

std::string CharLiteralExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "CharLiteral('" + value + "')" + typeAnnot(inferredType);
}

std::string BoolLiteralExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "BoolLiteral(" + (value ? "true" : "false") + ")" + typeAnnot(inferredType);
}

std::string NullLiteralExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "NullLiteral" + typeAnnot(inferredType);
}

std::string IdentifierExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "Identifier(" + name + ")" + typeAnnot(inferredType);
}

std::string ScopedIdentifierExprAST::toTreeString(int indent) const {
    return makeIndent(indent) + "ScopedIdentifier(" + scopeName + "::" + memberName + ")" + typeAnnot(inferredType);
}

std::string BinaryExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "BinaryExpr(" + op + ")" + typeAnnot(inferredType) + "\n";
    res += left ? left->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    res += "\n";
    res += right ? right->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    return res;
}

std::string UnaryExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "UnaryExpr(" + op + ")" + typeAnnot(inferredType) + "\n";
    if (typeOperand) {
        res += typeOperand->toTreeString(indent + 1);
    } else {
        res += operand ? operand->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    }
    return res;
}

std::string MemberAccessExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "MemberAccess(" + (isPointerArrow ? "->" : ".") + memberName + ")" + typeAnnot(inferredType) + "\n";
    res += object ? object->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    return res;
}

std::string CallExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "CallExpr" + typeAnnot(inferredType) + "\n";
    res += makeIndent(indent + 1) + "Callee:\n";
    res += callee ? callee->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>";
    if (!arguments.empty()) {
        res += "\n" + makeIndent(indent + 1) + "Arguments:\n";
        for (size_t i = 0; i < arguments.size(); ++i) {
            if (i > 0) res += "\n";
            res += arguments[i] ? arguments[i]->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>";
        }
    }
    return res;
}

std::string StaticMethodCallExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "StaticMethodCall(" + targetType + "::" + methodName + ")" + typeAnnot(inferredType);
    if (!arguments.empty()) {
        res += "\n" + makeIndent(indent + 1) + "Arguments:\n";
        for (size_t i = 0; i < arguments.size(); ++i) {
            if (i > 0) res += "\n";
            res += arguments[i] ? arguments[i]->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>";
        }
    }
    return res;
}

std::string StructInitExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "StructInit(" + (structType ? structType->name : "?") + ")" + typeAnnot(inferredType);
    for (const auto& f : fieldInits) {
        res += "\n" + makeIndent(indent + 1) + f.first + ":\n";
        res += f.second ? f.second->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>";
    }
    return res;
}

std::string YieldExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "YieldExpr" + typeAnnot(inferredType) + "\n";
    res += yieldedExpr ? yieldedExpr->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    return res;
}

std::string BlockExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "BlockExpr" + typeAnnot(inferredType);
    for (const auto& stmt : statements) {
        res += "\n" + (stmt ? stmt->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>");
    }
    if (yieldExpr) {
        res += "\n" + makeIndent(indent + 1) + "YieldValue:\n" + yieldExpr->toTreeString(indent + 2);
    }
    return res;
}

std::string IfExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "IfExpr" + typeAnnot(inferredType) + "\n";
    res += makeIndent(indent + 1) + "Condition:\n" + (condition ? condition->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>") + "\n";
    res += makeIndent(indent + 1) + "Then:\n" + (thenBranch ? thenBranch->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    if (elseBranch) {
        res += "\n" + makeIndent(indent + 1) + "Else:\n" + elseBranch->toTreeString(indent + 2);
    }
    return res;
}

std::string SwitchExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "SwitchExpr" + typeAnnot(inferredType) + "\n";
    res += makeIndent(indent + 1) + "Target:\n" + (targetExpr ? targetExpr->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    for (const auto& c : cases) {
        res += "\n" + makeIndent(indent + 1) + "Case (" + (c.pattern ? c.pattern->toTreeString(0) : "default") + "):\n";
        res += c.body ? c.body->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>";
    }
    return res;
}

std::string ClosureExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "ClosureExpr" + typeAnnot(inferredType) + "\n";
    res += makeIndent(indent + 1) + "Params: ";
    for (size_t i = 0; i < params.size(); ++i) {
        if (i > 0) res += ", ";
        res += params[i].name;
        if (params[i].typeAst) res += " : " + params[i].typeAst->name;
    }
    res += "\n" + makeIndent(indent + 1) + "Body:\n";
    res += body ? body->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>";
    return res;
}

std::string AssignExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "AssignExpr(" + op + ")" + typeAnnot(inferredType) + "\n";
    res += target ? target->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    res += "\n" + (value ? value->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>");
    return res;
}

std::string CastExprAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "CastExpr(" + (targetTypeAst ? targetTypeAst->name : "?") + ")" + typeAnnot(inferredType) + "\n";
    res += expr ? expr->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    return res;
}

static std::string formatAttributes(const std::vector<Attribute>& attrs) {
    if (attrs.empty()) return "";
    std::string res = "[";
    for (size_t i = 0; i < attrs.size(); ++i) {
        if (i > 0) res += ", ";
        res += attrs[i].name;
        if (!attrs[i].args.empty()) {
            res += "(";
            for (size_t j = 0; j < attrs[i].args.size(); ++j) {
                if (j > 0) res += ", ";
                if (!attrs[i].args[j].name.empty()) {
                    res += attrs[i].args[j].name + " = ";
                }
                res += attrs[i].args[j].value ? attrs[i].args[j].value->toTreeString(0) : "null";
            }
            res += ")";
        }
    }
    res += "] ";
    return res;
}

std::string VarDeclStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + formatAttributes(attributes) + "VarDecl(" + (isStatic ? "static " : "") + (isConst ? "const " : "") + name + (typeAst ? " : " + typeAst->name : " : auto") + ")";
    if (initializer) {
        res += "\n" + initializer->toTreeString(indent + 1);
    }
    return res;
}

std::string ExprStmtAST::toTreeString(int indent) const {
    return expr ? expr->toTreeString(indent) : makeIndent(indent) + "ExprStmt(<null>)";
}

std::string ReturnStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "ReturnStmt";
    if (value) {
        res += "\n" + value->toTreeString(indent + 1);
    }
    return res;
}

std::string YieldStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "YieldStmt";
    if (value) {
        res += "\n" + value->toTreeString(indent + 1);
    }
    return res;
}

std::string BreakStmtAST::toTreeString(int indent) const {
    return makeIndent(indent) + "BreakStmt";
}

std::string ContinueStmtAST::toTreeString(int indent) const {
    return makeIndent(indent) + "ContinueStmt";
}

std::string DeferStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "DeferStmt\n";
    res += deferredStmt ? deferredStmt->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>";
    return res;
}

std::string ImportStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "ImportStatement:";
    for (const auto& item : items) {
        res += "\n" + makeIndent(indent + 1) + "- Module: " + item.modulePath;
        if (!item.selectiveSymbols.empty()) {
            res += " (Selective: ";
            for (size_t i = 0; i < item.selectiveSymbols.size(); ++i) {
                if (i > 0) res += ", ";
                res += item.selectiveSymbols[i];
            }
            res += ")";
        }
    }
    return res;
}

std::string WhileStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "WhileStmt\n";
    res += makeIndent(indent + 1) + "Condition:\n" + (condition ? condition->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>") + "\n";
    res += makeIndent(indent + 1) + "Body:\n" + (body ? body->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    return res;
}

std::string DoWhileStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "DoWhileStmt\n";
    res += makeIndent(indent + 1) + "Body:\n" + (body ? body->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>") + "\n";
    res += makeIndent(indent + 1) + "Condition:\n" + (condition ? condition->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    return res;
}

std::string ForStmtAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "ForStmt\n";
    res += makeIndent(indent + 1) + "Init:\n" + (init ? init->toTreeString(indent + 2) : makeIndent(indent + 2) + "<none>") + "\n";
    res += makeIndent(indent + 1) + "Condition:\n" + (condition ? condition->toTreeString(indent + 2) : makeIndent(indent + 2) + "<none>") + "\n";
    res += makeIndent(indent + 1) + "Post:\n" + (post ? post->toTreeString(indent + 2) : makeIndent(indent + 2) + "<none>") + "\n";
    res += makeIndent(indent + 1) + "Body:\n" + (body ? body->toTreeString(indent + 2) : makeIndent(indent + 2) + "<null>");
    return res;
}

std::string StructDeclAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "StructDecl(" + name + ")";
    if (!typeParams.empty()) {
        res += "<";
        for (size_t i = 0; i < typeParams.size(); ++i) {
            if (i > 0) res += ", ";
            res += typeParams[i];
        }
        res += ">";
    }
    for (const auto& alias : typeAliases) {
        if (alias) {
            res += "\n" + alias->toTreeString(indent + 1);
        }
    }
    for (const auto& f : fields) {
        res += "\n" + makeIndent(indent + 1) + f.name + " : " + (f.typeAst ? f.typeAst->toTreeString(0) : "auto");
    }
    return res;
}

std::string UnionDeclAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "UnionDecl(" + name + ")";
    for (const auto& f : fields) {
        res += "\n" + makeIndent(indent + 1) + f.name + " : " + (f.typeAst ? f.typeAst->toTreeString(0) : "auto");
    }
    return res;
}

std::string EnumDeclAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "EnumDecl(" + name + ") { ";
    for (size_t i = 0; i < enumerators.size(); ++i) {
        if (i > 0) res += ", ";
        res += enumerators[i];
    }
    res += " }";
    return res;
}

std::string FunctionDeclAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + formatAttributes(attributes) + "FunctionDecl(";
    if (!ownerTypeName.empty()) res += ownerTypeName + "::";
    res += name + ")";
    if (!typeParams.empty()) {
        res += "<";
        for (size_t i = 0; i < typeParams.size(); ++i) {
            if (i > 0) res += ", ";
            res += typeParams[i];
        }
        res += ">";
    }
    res += "(";
    for (size_t i = 0; i < parameters.size(); ++i) {
        if (i > 0) res += ", ";
        res += parameters[i].name + " : " + (parameters[i].typeAst ? parameters[i].typeAst->toTreeString(0) : "auto");
    }
    res += ")";
    if (returnTypeAst) res += " -> " + returnTypeAst->toTreeString(0);
    if (body) {
        res += "\n" + body->toTreeString(indent + 1);
    }
    return res;
}

std::string TypeAliasDeclAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "TypeAlias(" + aliasName;
    if (!typeParams.empty()) {
        res += "<";
        for (size_t i = 0; i < typeParams.size(); ++i) {
            if (i > 0) res += ", ";
            res += typeParams[i];
        }
        res += ">";
    }
    res += " = " + (targetTypeAst ? targetTypeAst->toTreeString(0) : "?") + ")";
    return res;
}

std::string TypeAliasStmtAST::toTreeString(int indent) const {
    return decl ? decl->toTreeString(indent) : makeIndent(indent) + "TypeAliasStmt(<null>)";
}

std::string ProgramAST::toTreeString(int indent) const {
    std::string res = makeIndent(indent) + "ProgramAST\n";
    for (const auto& imp : imports) {
        res += imp.toTreeString(indent + 1) + "\n";
    }
    for (const auto& decl : declarations) {
        res += (decl ? decl->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>") + "\n";
    }
    for (const auto& stmt : topStatements) {
        res += (stmt ? stmt->toTreeString(indent + 1) : makeIndent(indent + 1) + "<null>") + "\n";
    }
    return res;
}

}  // namespace Glang
