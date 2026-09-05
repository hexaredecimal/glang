#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifdef max
#undef max
#endif
#ifdef min
#undef min
#endif

#include "compiler/LSPServer.hpp"
#include "compiler/Lexer.hpp"
#include "compiler/Parser.hpp"
#include "compiler/TypeChecker.hpp"
#include "compiler/SymbolQuery.hpp"
#include "compiler/CompilerError.hpp"

#include <chrono>
#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <algorithm>
#include <vector>
#include <string>
#include <memory>
#include <iomanip>
#include <mutex>
#include <atomic>

#include <lsp/connection.h>
#include <lsp/io/socket.h>
#include <lsp/io/standardio.h>
#include <lsp/messagehandler.h>
#include <lsp/messages.h>
#include <lsp/process.h>

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#elif defined(__linux__)
#include <unistd.h>
#endif

namespace fs = std::filesystem;

namespace Glang {

	static fs::path getCompilerDirectory() {
		try {
			std::error_code ec;
#if defined(__linux__)
			fs::path exePath = fs::read_symlink("/proc/self/exe", ec);
			if (!ec && !exePath.empty() && fs::exists(exePath, ec)) {
				return exePath.parent_path();
			}
#elif defined(__APPLE__)
			char buf[1024];
			uint32_t size = sizeof(buf);
			if (_NSGetExecutablePath(buf, &size) == 0) {
				fs::path exePath(buf);
				if (fs::exists(exePath, ec)) return exePath.parent_path();
			}
#elif defined(_WIN32)
			char buf[MAX_PATH];
			if (GetModuleFileNameA(NULL, buf, MAX_PATH) > 0) {
				fs::path exePath(buf);
				if (fs::exists(exePath, ec)) return exePath.parent_path();
			}
#endif
			return fs::current_path(ec);
		}
		catch (...) {
			return fs::path(".");
		}
	}

	static void logLSP(const std::string& msg) {
		static std::mutex s_logMutex;
		std::lock_guard<std::mutex> lock(s_logMutex);

		std::cerr << msg << std::endl;

		try {
			static fs::path logFilePath = getCompilerDirectory() / "lsp_debug.log";
			static std::ofstream logFile(logFilePath, std::ios::out | std::ios::app);
			if (logFile.is_open()) {
				auto now = std::chrono::system_clock::now();
				auto in_time_t = std::chrono::system_clock::to_time_t(now);
				auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
				std::tm buf{};
#if defined(_WIN32)
				localtime_s(&buf, &in_time_t);
#else
				localtime_r(&in_time_t, &buf);
#endif
				char timeStr[64];
				std::strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", &buf);
				logFile << "[" << timeStr << "." << std::setfill('0') << std::setw(3) << ms.count() << "] " << msg << "\n";
				logFile.flush();
			}
		}
		catch (...) {}
	}

	template<typename MessageType>
	static void printMessageMethod() {
		const auto type = lsp::message::IsNotification<MessageType> ? "notification" : "request";
		logLSP(std::string("Server received ") + type + " '" + std::string(MessageType::Method) + "'");
	}

	template<typename MessageType>
	static void printMessagePayload(const typename MessageType::Params& params) {
		const auto json = lsp::toJson(typename MessageType::Params(params));
		logLSP(std::string("payload: ") + lsp::json::stringify(json, true));
	}

	template<typename MessageType>
	static void printMessage(const typename MessageType::Params& params) {
		printMessageMethod<MessageType>();
		printMessagePayload<MessageType>(params);
	}

	template<typename MessageType>
	static void printMessage() {
		printMessageMethod<MessageType>();
	}

	static std::string uriToPath(const std::string& uri) {
		std::string path = uri;
                if (path.rfind("file:// Note: ", 0) == 0) {
                  path = path.substr(7);
#ifdef _WIN32
			if (path.size() >= 3 && path[0] == '/' && path[2] == ':') {
				path = path.substr(1);
			}
#endif
                }
                return path;
        }

	static std::string pathToUri(const std::string& path) {
          if (path.rfind("file:// Note: ", 0) == 0) {
            return path;
          }
          std::string normPath = path;
          try {
            std::error_code ec;
            normPath = fs::absolute(path, ec).string();
          } catch (...) {}
		std::replace(normPath.begin(), normPath.end(), '\\', '/');
		if (!normPath.empty() && normPath[0] != '/') {
			normPath = "/" + normPath;
		}
                return "file:// Note: " + normPath;
        }

        static bool findAndReadFile(const std::string& requestedPath, std::string& outCode, std::string& outResolvedPath) {
		if (requestedPath.empty()) return false;

		fs::path p(requestedPath);
		std::error_code ec;
		if (fs::exists(p, ec) && fs::is_regular_file(p, ec)) {
			std::ifstream ifs(p);
			if (ifs.is_open()) {
				std::stringstream ss;
				ss << ifs.rdbuf();
				outCode = ss.str();
				outResolvedPath = p.string();
				return true;
			}
		}

		fs::path cwd = fs::current_path(ec);
		std::vector<fs::path> candidateBases = {
			cwd,
			cwd / "tests",
			cwd / "cpp",
			cwd / "cpp" / "tests",
			cwd / "..",
			cwd / ".." / "tests",
			cwd / ".." / "cpp"
		};

		for (const auto& base : candidateBases) {
			fs::path candidate = base / requestedPath;
			if (fs::exists(candidate, ec) && fs::is_regular_file(candidate, ec)) {
				std::ifstream ifs(candidate);
				if (ifs.is_open()) {
					std::stringstream ss;
					ss << ifs.rdbuf();
					outCode = ss.str();
					outResolvedPath = candidate.string();
					return true;
				}
			}
		}

		return false;
	}

        class LanguageServer {
         public:
          LanguageServer(lsp::io::Stream& io, LSPServer* parent)
              : m_connection{io},
                m_messageHandler{m_connection},
                m_parent{parent} {
            registerCallbacks();
            m_state.store(State::Uninitialized);
          }

          bool isRunning() {
            return m_state.load() != State::Inactive &&
                   (m_parentProcessId.isNull() ||
                    lsp::Process::exists(*m_parentProcessId));
          }

          int run() {
            try {
              while (isRunning()) {
                m_messageHandler.processIncomingMessages();
              }
            } catch (const std::exception& e) {
              logLSP(std::string("ERROR: ") + e.what());
              return EXIT_FAILURE;
            }
            return EXIT_SUCCESS;
          }

          auto initialize(lsp::InitializeParams&& params)
              -> lsp::requests::Initialize::Result {
            logLSP("INITIALIZE");
            printMessage<lsp::requests::Initialize>(params);

            if (m_state > State::Uninitialized) {
              throw lsp::RequestError(lsp::MessageError::InvalidRequest,
                                      "Already initialized");
            }

            m_state.store(State::Active);
            m_parentProcessId = params.processId;

            lsp::InitializeResult result;
            result.capabilities.positionEncoding =
                lsp::PositionEncodingKind::UTF16;
            result.capabilities.textDocumentSync = lsp::TextDocumentSyncOptions{
                .openClose = true,
                .change = lsp::TextDocumentSyncKind::Full,
                .save = true};
            result.capabilities.hoverProvider = true;
            result.capabilities.completionProvider = lsp::CompletionOptions{
                .triggerCharacters = std::vector<std::string>{".", ":"},
                .resolveProvider = false};
            result.capabilities.definitionProvider = true;
            result.capabilities.documentSymbolProvider = true;
            result.capabilities.signatureHelpProvider =
                lsp::SignatureHelpOptions{
                    .triggerCharacters = std::vector<std::string>{"(", ","}};

            result.serverInfo =
                lsp::ServerInfo{.name = "glang-lsp-server", .version = "1.0.0"};

            return result;
          }

          void initialized(lsp::notifications::Initialized::Params&& params) {
            printMessage<lsp::notifications::Initialized>(params);
            logLSP("Client successfully initialized!");
          }

          void textDocumentDidOpen(
              lsp::notifications::TextDocument_DidOpen::Params&& params) {
            verifyInitialized();
            printMessage<lsp::notifications::TextDocument_DidOpen>(params);

            std::string uriStr = params.textDocument.uri.toString();
            if (m_parent) {
              m_parent->openDocument(uriStr, params.textDocument.text,
                                     params.textDocument.version);
              publishDiagnostics(params.textDocument.uri);
            }
          }

          void textDocumentDidChange(
              lsp::notifications::TextDocument_DidChange::Params&& params) {
            verifyInitialized();
            printMessage<lsp::notifications::TextDocument_DidChange>(params);

            std::string uriStr = params.textDocument.uri.toString();
            if (m_parent && !params.contentChanges.empty()) {
              // Note:  Full sync provides the new document content in the last
              // change Note:  element
              const auto& lastChange = params.contentChanges.back();
              std::string newText = std::visit(
                  [](const auto& c) -> std::string { return c.text; },
                  lastChange);
              m_parent->updateDocument(uriStr, newText,
                                       params.textDocument.version);
              publishDiagnostics(params.textDocument.uri);
            }
          }

          void textDocumentDidSave(
              lsp::notifications::TextDocument_DidSave::Params&& params) {
            verifyInitialized();
            printMessage<lsp::notifications::TextDocument_DidSave>(params);
            publishDiagnostics(params.textDocument.uri);
          }

          void textDocumentDidClose(
              lsp::notifications::TextDocument_DidClose::Params&& params) {
            printMessage<lsp::notifications::TextDocument_DidClose>(params);
            std::string uriStr = params.textDocument.uri.toString();
            if (m_parent) {
              m_parent->closeDocument(uriStr);
            }
          }

          auto hover(lsp::requests::TextDocument_Hover::Params&& params)
              -> lsp::requests::TextDocument_Hover::Result {
            printMessage<lsp::requests::TextDocument_Hover>(params);
            verifyInitialized();

            std::string uriStr = params.textDocument.uri.toString();
            DocumentState* doc =
                m_parent ? m_parent->getDocument(uriStr) : nullptr;
            if (!doc) {
              return lsp::Null{};
            }

            try {
              SymbolQueryEngine engine(doc->ast, doc->tokens, doc->symbolTable);
              std::string filePath = uriToPath(uriStr);
              int line = static_cast<int>(params.position.line) + 1;
              int col = static_cast<int>(params.position.character) + 1;

              auto qRes = engine.query(filePath, line, col);
              if (qRes.found) {
                std::ostringstream md;
                std::string sig;
                if (!qRes.signature.empty()) {
                  sig = qRes.signature;
                } else if (qRes.kind == "function" ||
                           qRes.kind == "static_method" ||
                           qRes.kind == "method") {
                  auto fnSyms = doc->symbolTable.lookupFunctions(qRes.name);
                  if (fnSyms.empty()) {
                    std::string shortName = qRes.name;
                    size_t p = shortName.rfind("::");
                    if (p != std::string::npos)
                      shortName = shortName.substr(p + 2);
                    fnSyms = doc->symbolTable.lookupFunctions(shortName);
                  }
                  if (!fnSyms.empty() && fnSyms[0]->funcAST) {
                    const auto& fAST = fnSyms[0]->funcAST;
                    std::string retStr = fAST->returnTypeAst
                                             ? fAST->returnTypeAst->name
                                             : "void";
                    sig = retStr + " " + qRes.name + "(";
                    for (size_t i = 0; i < fAST->parameters.size(); ++i) {
                      if (i > 0) sig += ", ";
                      const auto& p = fAST->parameters[i];
                      sig +=
                          (p.typeAst ? p.typeAst->name : "auto") + " " + p.name;
                    }
                    sig += ")";
                  } else if (!fnSyms.empty() && fnSyms[0]->type &&
                             fnSyms[0]->type->isFunction()) {
                    auto ft = fnSyms[0]->type;
                    std::string retStr =
                        ft->returnType ? ft->returnType->toString() : "void";
                    sig = retStr + " " + qRes.name + "(";
                    for (size_t i = 0; i < ft->paramTypes.size(); ++i) {
                      if (i > 0) sig += ", ";
                      sig += ft->paramTypes[i] ? ft->paramTypes[i]->toString()
                                               : "auto";
                    }
                    sig += ")";
                  } else {
                    sig = qRes.type.empty() ? qRes.name
                                            : (qRes.type + " " + qRes.name);
                  }
                } else {
                  sig = qRes.type.empty() ? qRes.name
                                          : (qRes.type + " " + qRes.name);
                }

                md << "```c\n" << sig << "\n```";
                if (!qRes.doc.empty()) {
                  md << "\n\n" << qRes.doc;
                }
                if (!qRes.members.empty()) {
                  md << "\n\n**Members:**\n";
                  for (const auto& m : qRes.members) {
                    md << "- `" << m.name << "`: `" << m.type << "`";
                    if (!m.doc.empty()) md << " — *" << m.doc << "*";
                    md << "\n";
                  }
                }

                lsp::Hover h;
                h.contents = lsp::MarkupContent{
                    .kind = lsp::MarkupKind::Markdown, .value = md.str()};
                return lsp::requests::TextDocument_Hover::Result(std::move(h));
              }
            } catch (const std::exception& e) {
              logLSP(std::string("Hover query exception: ") + e.what());
            }

            return lsp::Null{};
          }

          auto completion(
              lsp::requests::TextDocument_Completion::Params&& params)
              -> lsp::requests::TextDocument_Completion::Result {
            printMessage<lsp::requests::TextDocument_Completion>(params);
            verifyInitialized();

            std::string uriStr = params.textDocument.uri.toString();
            DocumentState* doc =
                m_parent ? m_parent->getDocument(uriStr) : nullptr;

            lsp::CompletionList compList;
            compList.isIncomplete = false;

            if (!doc) {
              return compList;
            }

            try {
              SymbolQueryEngine engine(doc->ast, doc->tokens, doc->symbolTable);
              std::string filePath = uriToPath(uriStr);
              int line = static_cast<int>(params.position.line) + 1;
              int col = static_cast<int>(params.position.character) + 1;

              auto qRes = engine.query(filePath, line, col);

              auto appendItem = [&](const std::string& label,
                                    const std::string& detail,
                                    lsp::CompletionItemKind kind,
                                    const std::string& docText) {
                lsp::CompletionItem item;
                item.label = label;
                item.kind = kind;
                item.detail = detail;
                item.insertText = label;
                if (!docText.empty()) {
                  item.documentation = lsp::MarkupContent{
                      .kind = lsp::MarkupKind::Markdown, .value = docText};
                }
                compList.items.push_back(std::move(item));
              };

              if (qRes.found && !qRes.members.empty()) {
                for (const auto& m : qRes.members) {
                  lsp::CompletionItemKind kind =
                      lsp::CompletionItemKind::Property;
                  if (m.kind == "field")
                    kind = lsp::CompletionItemKind::Field;
                  else if (m.kind == "enum_member")
                    kind = lsp::CompletionItemKind::EnumMember;
                  else if (m.kind == "static_method" || m.kind == "function" ||
                           m.kind == "method")
                    kind = lsp::CompletionItemKind::Method;
                  std::string detail =
                      !m.signature.empty() ? m.signature : m.type;
                  appendItem(m.name, detail, kind, m.doc);
                }
              } else {
                for (const auto& cand : engine.candidates()) {
                  if (cand.kind == "parameter") {
                    // Note:  NOTE: Do not use function parameter names in
                    // normal Note:  suggestions unless currently in scope!
                    if (cand.scopeStart.line > 0) {
                      if (line < cand.scopeStart.line ||
                          (cand.scopeEnd.line > 0 &&
                           line > cand.scopeEnd.line)) {
                        continue;
                      }
                    }
                  }

                  lsp::CompletionItemKind kind =
                      lsp::CompletionItemKind::Variable;
                  if (cand.kind == "function")
                    kind = lsp::CompletionItemKind::Function;
                  else if (cand.kind == "struct")
                    kind = lsp::CompletionItemKind::Struct;
                  else if (cand.kind == "enum")
                    kind = lsp::CompletionItemKind::Enum;
                  else if (cand.kind == "enum_member")
                    kind = lsp::CompletionItemKind::EnumMember;
                  else if (cand.kind == "constant")
                    kind = lsp::CompletionItemKind::Constant;
                  else if (cand.kind == "parameter")
                    kind = lsp::CompletionItemKind::Variable;

                  std::string detail =
                      !cand.signature.empty()
                          ? cand.signature
                          : (cand.type ? cand.type->toString() : "");
                  appendItem(cand.name, detail, kind, cand.doc);
                }

                static const std::vector<std::string> keywords = {
                    "fn",       "struct", "enum",   "union", "type",  "const",
                    "static",   "auto",   "return", "if",    "else",  "while",
                    "for",      "switch", "case",   "defer", "yield", "break",
                    "continue", "cast",   "null",   "true",  "false", "int",
                    "float",    "bool",   "string", "void"};
                for (const auto& kw : keywords) {
                  appendItem(kw, "keyword", lsp::CompletionItemKind::Keyword,
                             "");
                }
              }
            } catch (const std::exception& e) {
              logLSP(std::string("Completion exception: ") + e.what());
            }

            return compList;
          }

          auto definition(
              lsp::requests::TextDocument_Definition::Params&& params)
              -> lsp::requests::TextDocument_Definition::Result {
            printMessage<lsp::requests::TextDocument_Definition>(params);
            verifyInitialized();

            std::string uriStr = params.textDocument.uri.toString();
            DocumentState* doc =
                m_parent ? m_parent->getDocument(uriStr) : nullptr;
            if (!doc) {
              return lsp::Null{};
            }

            try {
              SymbolQueryEngine engine(doc->ast, doc->tokens, doc->symbolTable);
              std::string filePath = uriToPath(uriStr);
              int line = static_cast<int>(params.position.line) + 1;
              int col = static_cast<int>(params.position.character) + 1;

              auto qRes = engine.query(filePath, line, col);
              if (qRes.found && qRes.declLine > 0) {
                std::string targetPath =
                    qRes.file.empty() ? filePath : qRes.file;
                lsp::uint targetLine =
                    static_cast<lsp::uint>((std::max)(0, qRes.declLine - 1));
                lsp::uint targetCol =
                    static_cast<lsp::uint>((std::max)(0, qRes.declColumn - 1));
                lsp::uint len = static_cast<lsp::uint>(qRes.name.length());

                lsp::Location loc;
                loc.uri = lsp::Uri::fileUriFromPath(targetPath);
                loc.range.start.line = targetLine;
                loc.range.start.character = targetCol;
                loc.range.end.line = targetLine;
                loc.range.end.character = targetCol + len;

                return loc;
              }
            } catch (const std::exception& e) {
              logLSP(std::string("Definition query exception: ") + e.what());
            }

            return lsp::Null{};
          }

          auto documentSymbol(
              lsp::requests::TextDocument_DocumentSymbol::Params&& params)
              -> lsp::requests::TextDocument_DocumentSymbol::Result {
            printMessage<lsp::requests::TextDocument_DocumentSymbol>(params);
            verifyInitialized();

            std::string uriStr = params.textDocument.uri.toString();
            DocumentState* doc =
                m_parent ? m_parent->getDocument(uriStr) : nullptr;
            std::vector<lsp::DocumentSymbol> symbols;

            if (!doc || !doc->ast) {
              return symbols;
            }

            try {
              auto appendSym = [&](const std::string& name,
                                   lsp::SymbolKind kind, int line, int col,
                                   int endLine, int endCol) {
                lsp::DocumentSymbol sym;
                sym.name = name;
                sym.kind = kind;

                lsp::uint startL =
                    static_cast<lsp::uint>((std::max)(0, line - 1));
                lsp::uint startC =
                    static_cast<lsp::uint>((std::max)(0, col - 1));
                lsp::uint stopL = static_cast<lsp::uint>(
                    (std::max)(static_cast<int>(startL), endLine - 1));
                lsp::uint stopC = static_cast<lsp::uint>(
                    (std::max)(static_cast<int>(startC) + 1, endCol - 1));

                sym.range.start.line = startL;
                sym.range.start.character = startC;
                sym.range.end.line = stopL;
                sym.range.end.character = stopC;

                sym.selectionRange.start.line = startL;
                sym.selectionRange.start.character = startC;
                sym.selectionRange.end.line = startL;
                sym.selectionRange.end.character =
                    startC + static_cast<lsp::uint>(name.length());

                symbols.push_back(std::move(sym));
              };

              for (const auto& decl : doc->ast->declarations) {
                if (!decl) continue;
                if (auto f = std::dynamic_pointer_cast<FunctionDeclAST>(decl)) {
                  std::string fnName =
                      (f->ownerTypeName.empty() ? ""
                                                : f->ownerTypeName + "::") +
                      f->name;
                  appendSym(fnName, lsp::SymbolKind::Function, f->loc.line,
                            f->loc.column, f->loc.line,
                            f->loc.column + static_cast<int>(f->name.length()));
                } else if (auto s =
                               std::dynamic_pointer_cast<StructDeclAST>(decl)) {
                  appendSym(s->name, lsp::SymbolKind::Struct, s->loc.line,
                            s->loc.column, s->loc.line,
                            s->loc.column + static_cast<int>(s->name.length()));
                } else if (auto u =
                               std::dynamic_pointer_cast<UnionDeclAST>(decl)) {
                  appendSym(u->name, lsp::SymbolKind::Struct, u->loc.line,
                            u->loc.column, u->loc.line,
                            u->loc.column + static_cast<int>(u->name.length()));
                } else if (auto e =
                               std::dynamic_pointer_cast<EnumDeclAST>(decl)) {
                  appendSym(e->name, lsp::SymbolKind::Enum, e->loc.line,
                            e->loc.column, e->loc.line,
                            e->loc.column + static_cast<int>(e->name.length()));
                } else if (auto a = std::dynamic_pointer_cast<TypeAliasDeclAST>(
                               decl)) {
                  appendSym(
                      a->aliasName, lsp::SymbolKind::Interface, a->loc.line,
                      a->loc.column, a->loc.line,
                      a->loc.column + static_cast<int>(a->aliasName.length()));
                }
              }

              for (const auto& stmt : doc->ast->topStatements) {
                if (!stmt) continue;
                if (auto v = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
                  appendSym(v->name,
                            v->isConst ? lsp::SymbolKind::Constant
                                       : lsp::SymbolKind::Variable,
                            v->loc.line, v->loc.column, v->loc.line,
                            v->loc.column + static_cast<int>(v->name.length()));
                }
              }
            } catch (const std::exception& e) {
              logLSP(std::string("DocumentSymbol exception: ") + e.what());
            }

            return symbols;
          }

          auto signatureHelp(
              lsp::requests::TextDocument_SignatureHelp::Params&& params)
              -> lsp::requests::TextDocument_SignatureHelp::Result {
            printMessage<lsp::requests::TextDocument_SignatureHelp>(params);
            verifyInitialized();

            std::string uriStr = params.textDocument.uri.toString();
            DocumentState* doc =
                m_parent ? m_parent->getDocument(uriStr) : nullptr;
            if (!doc) {
              return lsp::Null{};
            }

            try {
              SymbolQueryEngine engine(doc->ast, doc->tokens, doc->symbolTable);
              std::string filePath = uriToPath(uriStr);
              int line = static_cast<int>(params.position.line) + 1;
              int col = static_cast<int>(params.position.character) + 1;

              // Note:  Scan tokens backward from (line, col) to find enclosing
              // '('
              int callParenIdx = -1;
              int parenDepth = 0;
              int commaCount = 0;

              int lastTokIdx = -1;
              for (int i = 0; i < static_cast<int>(doc->tokens.size()); ++i) {
                const auto& tok = doc->tokens[i];
                if (tok.loc.line < line ||
                    (tok.loc.line == line && tok.loc.column <= col)) {
                  lastTokIdx = i;
                } else {
                  break;
                }
              }

              for (int i = lastTokIdx; i >= 0; --i) {
                const auto& tok = doc->tokens[i];
                if (tok.kind == TokenKind::RParen) {
                  parenDepth++;
                } else if (tok.kind == TokenKind::LParen) {
                  if (parenDepth > 0) {
                    parenDepth--;
                  } else {
                    callParenIdx = i;
                    break;
                  }
                } else if (parenDepth == 0 && tok.kind == TokenKind::Comma) {
                  commaCount++;
                }
              }

              std::string targetFnName;
              bool isUFCS = false;

              if (callParenIdx > 0) {
                int nameIdx = callParenIdx - 1;
                if (doc->tokens[nameIdx].kind == TokenKind::Identifier) {
                  targetFnName = doc->tokens[nameIdx].lexeme;
                  if (nameIdx >= 1 &&
                      doc->tokens[nameIdx - 1].kind == TokenKind::Dot) {
                    isUFCS = true;
                  } else if (nameIdx >= 2 &&
                             doc->tokens[nameIdx - 1].kind ==
                                 TokenKind::DoubleColon &&
                             doc->tokens[nameIdx - 2].kind ==
                                 TokenKind::Identifier) {
                    targetFnName =
                        doc->tokens[nameIdx - 2].lexeme + "::" + targetFnName;
                  }
                }
              }

              int activeParam = isUFCS ? (commaCount + 1) : commaCount;

              std::shared_ptr<FunctionDeclAST> targetAST = nullptr;
              TypePtr targetFnType = nullptr;
              std::string targetDoc;

              if (!targetFnName.empty()) {
                auto fnSyms = doc->symbolTable.lookupFunctions(targetFnName);
                if (fnSyms.empty()) {
                  std::string shortName = targetFnName;
                  size_t p = shortName.rfind("::");
                  if (p != std::string::npos)
                    shortName = shortName.substr(p + 2);
                  fnSyms = doc->symbolTable.lookupFunctions(shortName);
                }
                if (!fnSyms.empty() && fnSyms[0]) {
                  targetAST = fnSyms[0]->funcAST;
                  targetFnType = fnSyms[0]->type;
                  if (targetAST && !targetAST->doc.empty())
                    targetDoc = targetAST->doc;
                }

                if (!targetAST) {
                  for (const auto& cand : engine.candidates()) {
                    if (cand.name == targetFnName &&
                        (cand.kind == "function" ||
                         cand.kind == "static_method" ||
                         cand.kind == "method")) {
                      targetFnType = cand.type;
                      targetDoc = cand.doc;
                      break;
                    }
                  }
                }
              }

              if (!targetAST && !targetFnType) {
                auto qRes = engine.query(filePath, line, col);
                if (qRes.found &&
                    (qRes.kind == "function" || qRes.kind == "static_method" ||
                     qRes.kind == "method")) {
                  targetFnName = qRes.name;
                  auto fnSyms = doc->symbolTable.lookupFunctions(targetFnName);
                  if (!fnSyms.empty() && fnSyms[0]) {
                    targetAST = fnSyms[0]->funcAST;
                    targetFnType = fnSyms[0]->type;
                  }
                  targetDoc = qRes.doc;
                }
              }

              if (targetAST || targetFnType) {
                lsp::SignatureHelp sigHelp;
                lsp::SignatureInformation sigInfo = {0};
                sigInfo.parameters.emplace();

                std::string fullSig;
                std::string currentExpectedType;
                std::string currentParamName;

                if (targetAST) {
                  std::string retStr = targetAST->returnTypeAst
                                           ? targetAST->returnTypeAst->name
                                           : "void";
                  fullSig = retStr + " " + targetFnName + "(";

                  size_t size = targetAST->parameters.size();
                  for (size_t i = 0; i < size; ++i) {
                    if (i > 0) fullSig += ", ";
                    const auto& p = targetAST->parameters[i];
                    std::string pTypeStr = p.typeAst ? p.typeAst->name : "auto";
                    std::string pLabel = pTypeStr + " " + p.name;
                    fullSig += pLabel;

                    lsp::ParameterInformation paramInfo;
                    paramInfo.label = pLabel;
                    if (!p.doc.empty()) {
                      paramInfo.documentation = lsp::MarkupContent{
                          .kind = lsp::MarkupKind::Markdown, .value = p.doc};
                    }
                    sigInfo.parameters->push_back(std::move(paramInfo));

                    if (static_cast<int>(i) == activeParam) {
                      currentExpectedType = pTypeStr;
                      currentParamName = p.name;
                    }
                  }
                  fullSig += ")";
                } else if (targetFnType && targetFnType->isFunction()) {
                  std::string retStr =
                      targetFnType->returnType
                          ? targetFnType->returnType->toString()
                          : "void";
                  fullSig = retStr + " " + targetFnName + "(";
                  for (size_t i = 0; i < targetFnType->paramTypes.size(); ++i) {
                    if (i > 0) fullSig += ", ";
                    std::string pTypeStr =
                        targetFnType->paramTypes[i]
                            ? targetFnType->paramTypes[i]->toString()
                            : "auto";
                    std::string pLabel = pTypeStr + " arg" + std::to_string(i);
                    fullSig += pLabel;

                    lsp::ParameterInformation paramInfo;
                    paramInfo.label = pLabel;
                    sigInfo.parameters->push_back(std::move(paramInfo));

                    if (static_cast<int>(i) == activeParam) {
                      currentExpectedType = pTypeStr;
                      currentParamName = "arg" + std::to_string(i);
                    }
                  }
                  fullSig += ")";
                }

                sigInfo.label = fullSig;

                std::ostringstream docMd;
                if (!currentExpectedType.empty()) {
                  docMd << "**Expected Type:** `" << currentExpectedType << "`";
                  if (!currentParamName.empty()) {
                    docMd << " (parameter `" << currentParamName << "`)";
                  }
                  docMd << "\n\n";
                }
                if (!targetDoc.empty()) {
                  docMd << targetDoc;
                }

                std::string docVal = docMd.str();
                if (!docVal.empty()) {
                  sigInfo.documentation = lsp::MarkupContent{
                      .kind = lsp::MarkupKind::Markdown, .value = docVal};
                }

                sigInfo.activeParameter =
                    static_cast<lsp::uint>((std::max)(0, activeParam));
                sigHelp.signatures.push_back(std::move(sigInfo));
                sigHelp.activeSignature = 0;
                sigHelp.activeParameter =
                    static_cast<lsp::uint>((std::max)(0, activeParam));
                return sigHelp;
              }
            } catch (const std::exception& e) {
              logLSP(std::string("SignatureHelp exception: ") + e.what());
            }

            return lsp::Null{};
          }

          auto shutdown() -> lsp::requests::Shutdown::Result {
            printMessage<lsp::requests::Shutdown>();
            m_state.store(State::Shutdown);
            return {};
          }

          void exit() {
            printMessage<lsp::notifications::Exit>();
            m_state.store(State::Inactive);
          }

          void publishDiagnostics(const lsp::DocumentUri& uri) {
            DocumentState* doc =
                m_parent ? m_parent->getDocument(uri.toString()) : nullptr;
            if (!doc) return;

            lsp::PublishDiagnosticsParams params;
            params.uri = uri;
            params.version = doc->version;

            for (const auto& d : doc->diagnostics) {
              lsp::Diagnostic diag;
              diag.range.start.line =
                  static_cast<lsp::uint>((std::max)(0, d.line - 1));
              diag.range.start.character =
                  static_cast<lsp::uint>((std::max)(0, d.column - 1));
              int tokLen =
                  d.token.empty() ? 1 : static_cast<int>(d.token.length());
              diag.range.end.line = diag.range.start.line;
              diag.range.end.character = diag.range.start.character + tokLen;
              diag.severity = lsp::DiagnosticSeverity::Error;
              diag.source = "c-like-compiler";
              diag.message = d.message;
              params.diagnostics.push_back(std::move(diag));
            }

            m_messageHandler.sendNotification<
                lsp::notifications::TextDocument_PublishDiagnostics>(
                std::move(params));
          }

         private:
          lsp::Connection m_connection;
          lsp::MessageHandler m_messageHandler;
          lsp::NullOr<int> m_parentProcessId;
          LSPServer* m_parent{nullptr};

          enum class State {
            Inactive,  // Note:  Initial state or exit notification received
            Uninitialized,  // Note:  Started up and waiting for initialize
                            // request
            Active,         // Note:  Currently handling requests
            Shutdown        // Note:  Shutdown notification received
          };

          std::atomic<State> m_state = State::Uninitialized;

          void verifyInitialized() const {
            if (m_state.load() <= State::Uninitialized) {
              throw lsp::RequestError(lsp::MessageError::ServerNotInitialized,
                                      "Server not initialized");
            }
            if (m_state.load() == State::Shutdown) {
              throw lsp::RequestError(lsp::MessageError::InvalidRequest,
                                      "Shutdown request received");
            }
          }

          void registerCallbacks() {
            m_messageHandler.add<lsp::requests::Initialize>(
                [this](lsp::requests::Initialize::Params&& params) {
                  return initialize(std::move(params));
                });
            m_messageHandler.add<lsp::notifications::Initialized>(
                [this](lsp::notifications::Initialized::Params&& params) {
                  initialized(std::move(params));
                });
            m_messageHandler.add<lsp::notifications::TextDocument_DidOpen>(
                [this](
                    lsp::notifications::TextDocument_DidOpen::Params&& params) {
                  textDocumentDidOpen(std::move(params));
                });
            m_messageHandler.add<lsp::notifications::TextDocument_DidChange>(
                [this](lsp::notifications::TextDocument_DidChange::Params&&
                           params) {
                  textDocumentDidChange(std::move(params));
                });
            m_messageHandler.add<lsp::notifications::TextDocument_DidSave>(
                [this](
                    lsp::notifications::TextDocument_DidSave::Params&& params) {
                  textDocumentDidSave(std::move(params));
                });
            m_messageHandler.add<lsp::notifications::TextDocument_DidClose>(
                [this](lsp::notifications::TextDocument_DidClose::Params&&
                           params) {
                  textDocumentDidClose(std::move(params));
                });
            m_messageHandler.add<lsp::requests::TextDocument_Hover>(
                [this](lsp::requests::TextDocument_Hover::Params&& params) {
                  return hover(std::move(params));
                });
            m_messageHandler.add<lsp::requests::TextDocument_Completion>(
                [this](
                    lsp::requests::TextDocument_Completion::Params&& params) {
                  return completion(std::move(params));
                });
            m_messageHandler.add<lsp::requests::TextDocument_Definition>(
                [this](
                    lsp::requests::TextDocument_Definition::Params&& params) {
                  return definition(std::move(params));
                });
            m_messageHandler.add<lsp::requests::TextDocument_DocumentSymbol>(
                [this](lsp::requests::TextDocument_DocumentSymbol::Params&&
                           params) {
                  return documentSymbol(std::move(params));
                });
            m_messageHandler.add<lsp::requests::TextDocument_SignatureHelp>(
                [this](lsp::requests::TextDocument_SignatureHelp::Params&&
                           params) {
                  return signatureHelp(std::move(params));
                });
            m_messageHandler.add<lsp::requests::Shutdown>(
                [this]() { return shutdown(); });
            m_messageHandler.add<lsp::notifications::Exit>(
                [this]() { exit(); });
          }
        };

        // Note:
        // ============================================================================
        // Note:  LSPServer Public Methods
        // Note:
        // ============================================================================

        LSPServer::LSPServer(const LSPServerConfig& config)
            : m_config(config) {}

        LSPServer::~LSPServer() = default;

        bool LSPServer::run() {
          fs::path dir = getCompilerDirectory();
          logLSP("=================================================");
          logLSP(
              "[LSP Startup] Language Server initialized with lsp-framework");
          logLSP("[LSP Startup] Compiler Directory: " + dir.string());
          logLSP("[LSP Startup] Debug Log File: " +
                 (dir / "lsp_debug.log").string());

          logLSP("Starting stdio server...");
          try {
            LanguageServer server(lsp::io::standardIO(), this);
            return server.run() == EXIT_SUCCESS;
          } catch (const std::exception& e) {
            logLSP(std::string("Stdio server error: ") + e.what());
            return false;
          }
        }

        void LSPServer::openDocument(const std::string& uri,
                                     const std::string& text, int version) {
          std::lock_guard<std::mutex> lock(m_docMutex);
          DocumentState state;
          state.uri = uri;
          state.text = text;
          state.version = version;

          std::string filePath = uriToPath(uri);

          try {
            Lexer lexer(filePath, text);
            state.tokens = lexer.tokenize();
            for (const auto& e : lexer.errors()) state.diagnostics.push_back(e);

            Parser parser(state.tokens);
            state.ast = parser.parseProgram();
            for (const auto& e : parser.errors())
              state.diagnostics.push_back(e);

            TypeChecker tc;
            auto tcRes = tc.check(state.ast);
            state.symbolTable = tc.symbolTable();
            for (const auto& e : tcRes.errors) state.diagnostics.push_back(e);
          } catch (const std::exception& e) {
            logLSP(std::string("Exception during document parsing: ") +
                   e.what());
            CompilerError err;
            err.filename = filePath;
            err.message = std::string("Internal parsing error: ") + e.what();
            err.line = 1;
            err.column = 1;
            state.diagnostics.push_back(err);
          } catch (...) {
            logLSP("Unknown exception during document parsing");
          }

          m_documents[uri] = std::move(state);
        }

        void LSPServer::updateDocument(const std::string& uri,
                                       const std::string& text, int version) {
          openDocument(uri, text, version);
        }

        void LSPServer::closeDocument(const std::string& uri) {
		std::lock_guard<std::mutex> lock(m_docMutex);
		m_documents.erase(uri);
	}

	DocumentState* LSPServer::getDocument(const std::string& uri) {
		std::lock_guard<std::mutex> lock(m_docMutex);
		auto it = m_documents.find(uri);
		if (it != m_documents.end()) {
			return &it->second;
		}
		return nullptr;
	}

	std::string LSPServer::processQuery(const std::string& code, const std::string& file, int line, int column, const std::string& symbol) {
		std::string actualCode = code;
		std::string resolvedFilename = file.empty() ? "main.cl" : file;

		if (actualCode.empty() && !file.empty()) {
			std::string foundPath;
			if (findAndReadFile(file, actualCode, foundPath)) {
				resolvedFilename = foundPath;
			}
			else {
				SymbolQueryResult err;
				err.found = false;
				err.file = file;
				err.line = line;
				err.column = column;
				err.type = "unknown";
				err.kind = "unknown";
				std::error_code ec;
				err.error = "File '" + file + "' could not be opened or found relative to server directory (" + fs::current_path(ec).string() + ")";
				return err.toJSON();
			}
		}

		Lexer lexer(resolvedFilename, actualCode);
		std::vector<Token> tokens = lexer.tokenize();

		Parser parser(tokens);
		auto ast = parser.parseProgram();

		TypeChecker typeChecker;
		typeChecker.check(ast);

		SymbolQueryEngine queryEngine(ast, tokens, typeChecker.symbolTable());
		SymbolQueryResult result = queryEngine.query(resolvedFilename, line, column, symbol);
		if (result.file.empty()) {
			result.file = resolvedFilename;
		}
		return result.toJSON();
	}

        }  // namespace Glang
