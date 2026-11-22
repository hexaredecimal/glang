#ifndef COMPILER_CPP_CODEGEN_HPP
#define COMPILER_CPP_CODEGEN_HPP

#include "AST.hpp"
#include "CompilerError.hpp"

#include <set>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

namespace Glang {

class CppCodeGen {
 public:
  std::string generate(const std::vector<ASTNodePtr>& nodes,
                       const std::vector<StmtPtr>& topStatements = {});

  const std::vector<Error>& errors() const { return m_errors; }
  bool hasErrors() const { return !m_errors.empty(); }

 private:
  std::string identifier(const std::string& name) const;
  std::string scopedVariableIdentifier(const std::string& name) const;
  std::string type(TypePtr type) const;
  std::string type(TypeASTPtr type) const;
  std::string declarator(TypePtr type, const std::string& name) const;
  std::string declarator(TypeASTPtr type, const std::string& name) const;
  std::string declaration(std::shared_ptr<FunctionDeclAST> function);
  std::string definition(std::shared_ptr<FunctionDeclAST> function);
  std::string structDeclaration(std::shared_ptr<StructDeclAST> decl);
  std::string unionDeclaration(std::shared_ptr<UnionDeclAST> decl);
  std::string statement(StmtPtr stmt, int indent);
  std::string block(std::shared_ptr<BlockExprAST> block, int indent,
                    bool functionBody = false);
  std::string expression(ExprPtr expr);
  std::string call(std::shared_ptr<CallExprAST> expr);
  std::string cast(std::shared_ptr<CastExprAST> expr);
  std::string indent(int level) const;

  struct CallTemporaries {
    std::vector<std::string> declarations;
  };
  std::string callArgument(ExprPtr argument, TypePtr parameterType,
                           CallTemporaries& temporaries);
  std::string wrapCall(const std::string& invocation,
                       const CallTemporaries& temporaries);
  std::string lambdaCapture() const;

  std::vector<Error> m_errors;
  size_t m_nextDeferId{0};
  size_t m_nextArrayId{0};
  size_t m_nextSwitchId{0};
  bool m_inMainFunction{false};
  bool m_inGlobalInitializer{false};
  std::set<std::string> m_coreTypes;
  std::set<std::string> m_listTypes;
  std::set<std::string> m_lazyTypes;
  std::map<std::string, std::vector<std::pair<std::string, TypePtr>>>
      m_functionNames;
  std::unordered_map<const ExprAST*, std::string> m_addressOfTemporaries;
};

}  // namespace Glang

#endif
