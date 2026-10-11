#ifndef COMPILER_LSPSERVER_HPP
#define COMPILER_LSPSERVER_HPP

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include "compiler/AST.hpp"
#include "compiler/Token.hpp"
#include "compiler/SymbolTable.hpp"
#include "compiler/CompilerError.hpp"

#include <string>
#include <memory>
#include <vector>
#include <unordered_map>
#include <mutex>

namespace Glang {

struct LSPServerConfig {
    bool verbose{false};
};

struct DocumentState {
    std::string uri;
    std::string text;
    int version{0};
    std::vector<Token> tokens;
    std::shared_ptr<ProgramAST> ast;
    SymbolTable symbolTable;
    std::vector<CompilerError> diagnostics;
};

class LSPServer {
public:
    explicit LSPServer(const LSPServerConfig& config = LSPServerConfig{});
    ~LSPServer();

    bool run();

    static std::string processQuery(const std::string& code, const std::string& file, int line, int column, const std::string& symbol);

    void openDocument(const std::string& uri, const std::string& text, int version = 1);
    void updateDocument(const std::string& uri, const std::string& text, int version = 1);
    void closeDocument(const std::string& uri);
    DocumentState* getDocument(const std::string& uri);

private:
    LSPServerConfig m_config;
    std::unordered_map<std::string, DocumentState> m_documents;
    std::mutex m_docMutex;
};

}  // namespace Glang

#endif // COMPILER_LSPSERVER_HPP
