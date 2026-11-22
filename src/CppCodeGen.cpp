#include "compiler/CppCodeGen.hpp"

#include <cctype>
#include <sstream>
#include <algorithm>
#include <cctype>
#include <functional>

namespace Glang {

static std::string cppLiteral(const std::string& value, char delimiter) {
  static const char hexDigits[] = "0123456789ABCDEF";
  std::string result(1, delimiter);
  for (size_t i = 0; i < value.size(); ++i) {
    const unsigned char c = static_cast<unsigned char>(value[i]);
    switch (c) {
      case '\0':
        result += "\\0";
        if (i + 1 < value.size() && value[i + 1] >= '0' &&
            value[i + 1] <= '7') {
          result += "\"\"";
        }
        break;
      case '\a':
        result += "\\a";
        break;
      case '\b':
        result += "\\b";
        break;
      case '\f':
        result += "\\f";
        break;
      case '\n':
        result += "\\n";
        break;
      case '\r':
        result += "\\r";
        break;
      case '\t':
        result += "\\t";
        break;
      case '\v':
        result += "\\v";
        break;
      case '\\':
        result += "\\\\";
        break;
      default:
        if (c == static_cast<unsigned char>(delimiter)) {
          result += '\\';
          result += delimiter;
        } else if (c < 0x20 || c == 0x7f) {
          result += "\\x";
          result += hexDigits[c >> 4];
          result += hexDigits[c & 0x0f];
          if (i + 1 < value.size() &&
              std::isxdigit(static_cast<unsigned char>(value[i + 1]))) {
            result += "\"\"";
          }
        } else {
          result += static_cast<char>(c);
        }
        break;
    }
  }
  result += delimiter;
  return result;
}

std::string CppCodeGen::indent(int level) const {
  return std::string(static_cast<size_t>(level * 2), ' ');
}

std::string CppCodeGen::lambdaCapture() const {
  return m_inGlobalInitializer ? "[]" : "[&]";
}

std::string CppCodeGen::identifier(const std::string& name) const {
  std::string result;
  result.reserve(name.size() + 1);
  for (unsigned char c : name) {
    result += (std::isalnum(c) || c == '_') ? static_cast<char>(c) : '_';
  }
  if (result.empty() || std::isdigit(static_cast<unsigned char>(result[0]))) {
    result.insert(result.begin(), '_');
  }
  static const std::set<std::string> keywords = {
      "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand",
      "bitor", "bool", "break", "case", "catch", "char", "char8_t",
      "char16_t", "char32_t", "class", "compl", "concept", "const",
      "consteval", "constexpr", "constinit", "const_cast", "continue",
      "co_await", "co_return", "co_yield", "decltype", "default", "delete",
      "do", "double", "dynamic_cast", "else", "enum", "explicit", "export",
      "extern", "false", "float", "for", "friend", "goto", "if", "import",
      "inline", "int", "long", "module", "mutable", "namespace", "new",
      "noexcept", "not", "not_eq", "nullptr", "operator", "or", "or_eq",
      "private", "protected", "public", "register", "reinterpret_cast",
      "requires", "return", "short", "signed", "sizeof", "static",
      "static_assert", "static_cast", "struct", "switch", "template", "this",
      "thread_local", "throw", "true", "try", "typedef",
      "typeid", "typename", "union", "unsigned", "using", "virtual", "void",
      "volatile", "wchar_t", "while", "xor", "xor_eq"};
  if (keywords.count(result)) result += "_";
  return result;
}

std::string CppCodeGen::scopedVariableIdentifier(
    const std::string& name) const {
  std::string result = "_glang_global_";
  size_t start = 0;
  while (start <= name.size()) {
    size_t separator = name.find("::", start);
    if (result.size() > std::string("_glang_global_").size()) {
      result += "__";
    }
    result += identifier(name.substr(
        start, separator == std::string::npos ? std::string::npos
                                               : separator - start));
    if (separator == std::string::npos) break;
    start = separator + 2;
  }
  return result;
}

static std::string cppPrimitive(const std::string& name) {
  if (name == "void" || name == "bool" || name == "char" ||
      name == "float" || name == "double") return name;
  if (name == "uchar") return  "unsigned char"; //"std::uint8_t";
  if (name == "short") return   "short"; // "std::int16_t";
  if (name == "ushort") return  "unsigned short"; //"std::uint16_t";
  if (name == "int") return "int"; // "std::int32_t";
  if (name == "uint") return "unsigned int"; //"std::uint32_t";
  if (name == "long") return "long int"; // "std::int64_t"
  if (name == "ulong") return "unsigned long int"; // "std::uint64_t";
  if (name == "size_t") return "std::size_t";
  return {};
}

static bool isSwitchIntegerType(TypePtr type) {
  TypePtr normalized = type ? type->underlyingType() : nullptr;
  if (!normalized) return false;
  if (normalized->isEnum()) return true;
  if (!normalized->isPrimitive()) return false;
  const std::string& name = normalized->name;
  return name == "bool" || name == "char" || name == "uchar" ||
         name == "short" || name == "ushort" || name == "int" ||
         name == "uint" || name == "long" || name == "ulong" ||
         name == "size_t";
}

static bool isCStringType(TypePtr type) {
  TypePtr normalized = type ? type->underlyingType() : nullptr;
  if (!normalized || !normalized->isPointer() || !normalized->pointerBase) {
    return false;
  }
  TypePtr base = normalized->pointerBase->underlyingType();
  return base && base->isPrimitive() && base->name == "char";
}

static std::string cppSpecializedName(const std::string& name) {  size_t open = name.find('<');
  if (open == std::string::npos) return name;
  size_t close = name.rfind('>');
  if (close == std::string::npos || close < open) return name;
  std::string result = name.substr(0, open) + "__";
  size_t argStart = open + 1;
  int depth = 0;
  bool first = true;
  for (size_t i = argStart; i <= close; ++i) {
    if (i < close && name[i] == '<') ++depth;
    else if (i < close && name[i] == '>') --depth;
    if (i == close || (name[i] == ',' && depth == 0)) {
      if (!first) result += "__";
      first = false;
      std::string arg = name.substr(argStart, i - argStart);
      size_t begin = arg.find_first_not_of(" \t");
      size_t end = arg.find_last_not_of(" \t");
      if (begin != std::string::npos) arg = arg.substr(begin, end - begin + 1);
      std::string primitive = cppPrimitive(arg);
      result += primitive.empty()
                    ? cppSpecializedName(arg)
                    : primitive;
      argStart = i + 1;
    }
  }
  return result;
}

static std::string typeASTSpelling(TypeASTPtr ast) {
  if (!ast) return "void";
  if (ast->isPointer) return typeASTSpelling(ast->pointerBase) + "*";
  if (ast->isArray) {
    return typeASTSpelling(ast->elementType) + "[" +
           std::to_string(ast->arraySize) + "]";
  }
  if (ast->isSlice || ast->isRuntimeSizedArray) {
    return typeASTSpelling(ast->elementType) + "[]";
  }
  if (ast->isMap) {
    return typeASTSpelling(ast->elementType) + "[" +
           typeASTSpelling(ast->keyType) + "]";
  }
  if (ast->isTuple) {
    std::string result = "(";
    for (size_t i = 0; i < ast->tupleElementTypes.size(); ++i) {
      if (i) result += ", ";
      result += typeASTSpelling(ast->tupleElementTypes[i]);
    }
    return result + ")";
  }

  std::string result =
      ast->resolvedName.empty() ? ast->name : ast->resolvedName;
  if (!ast->templateArgs.empty()) {
    result += "<";
    for (size_t i = 0; i < ast->templateArgs.size(); ++i) {
      if (i) result += ", ";
      result += typeASTSpelling(ast->templateArgs[i]);
    }
    result += ">";
  }
  if (ast->isConst) result = "const " + result;
  return result;
}

static std::string mangleTypeAST(TypeASTPtr ast) {
  if (!ast) return "v";
  if (ast->isPointer) return "P" + mangleTypeAST(ast->pointerBase);
  if (ast->isArray) {
    return "A" + std::to_string(ast->arraySize) + "_" +
           mangleTypeAST(ast->elementType);
  }
  if (ast->isSlice || ast->isRuntimeSizedArray) {
    return "Sl_" + mangleTypeAST(ast->elementType);
  }
  if (ast->isMap) {
    return "Map_" + mangleTypeAST(ast->keyType) + "_" +
           mangleTypeAST(ast->elementType);
  }

  const std::string name =
      ast->resolvedName.empty() ? ast->name : ast->resolvedName;
  static const std::map<std::string, std::string> primitives = {
      {"int", "i"},       {"uint", "u"},   {"bool", "b"},
      {"char", "c"},      {"uchar", "uc"}, {"short", "s"},
      {"ushort", "us"},   {"long", "l"},   {"ulong", "ul"},
      {"float", "f"},     {"double", "d"}, {"string", "str"},
      {"void", "v"}};
  auto primitive = primitives.find(name);
  if (primitive != primitives.end()) return primitive->second;

  auto encodeName = [](const std::string& value) {
    std::string encoded;
    for (unsigned char c : value) {
      encoded += (std::isalnum(c) || c == '_') ? static_cast<char>(c) : '_';
    }
    if (encoded.empty()) return std::string("anon");
    if (std::isdigit(static_cast<unsigned char>(encoded.front()))) {
      encoded.insert(encoded.begin(), '_');
    }
    return encoded;
  };
  std::string result = "S_" + encodeName(name);
  if (!ast->templateArgs.empty()) {
    result += "_G" + std::to_string(ast->templateArgs.size());
    for (const auto& arg : ast->templateArgs) {
      result += "_" + mangleTypeAST(arg);
    }
  }
  return result;
}

static bool hasFunctionAttribute(const FunctionDeclAST& function,
                                 const std::string& name) {
  for (const auto& attribute : function.attributes) {
    if (attribute.name == name) return true;
  }
  return false;
}

std::string CppCodeGen::type(TypePtr value) const {
  if (!value) return "void";
  TypePtr t = value->underlyingType();
  if (!t) return "void";
  if (t->isPrimitive()) {
    std::string primitive = cppPrimitive(t->name);
    if (!primitive.empty()) return t->isConst ? "const " + primitive
                                               : primitive;
    if (t->name == "auto") return "auto";
    return t->name;
  }
  if (t->isGenericParam()) return identifier(t->name);
  if (m_listTypes.count(t->name) && t->typeArgs.size() == 1) {
    return "std::vector<" + type(t->typeArgs[0]) + ">";
  }
  if (m_lazyTypes.count(t->name) && t->typeArgs.size() == 1) {
    return "glang::Lazy<" + type(t->typeArgs[0]) + ">";
  }
  if (m_coreTypes.count(t->name) && t->typeArgs.size() == 1) {
    return "std::shared_ptr<" + type(t->typeArgs[0]) + ">";
  }
  if (t->isPointer()) {
    if (t->pointerBase->isArray() || t->pointerBase->isHashMap())
       return type(t->pointerBase) + "&";
    return type(t->pointerBase) + "*";
  }
  if (t->isArray()) return type(t->elementType);
  if (t->isSlice()) return "std::span<" + type(t->elementType) + ">";
  if (t->isHashMap()) {
    return "std::unordered_map<" + type(t->keyType) + ", " +
           type(t->elementType) + ", glang::DeepHash, glang::DeepEqual>";
  }
  if (t->isTuple()) {
    std::string result = "std::tuple<";
    for (size_t i = 0; i < t->tupleElementTypes.size(); ++i) {
      if (i) result += ", ";
      result += type(t->tupleElementTypes[i]);
    }
    return result + ">";
  }
  if (t->isFunction() || t->isClosure()) {
    std::string result = "std::function<" +
                         (t->returnType ? type(t->returnType) : "void") + "(";
    for (size_t i = 0; i < t->paramTypes.size(); ++i) {
      if (i) result += ", ";
      result += type(t->paramTypes[i]);
    }
    return result + ")>";
  }
  return identifier(cppSpecializedName(t->toString()));
}

std::string CppCodeGen::type(TypeASTPtr ast) const {
  if (!ast) return "void";
  if (ast->isPointer) {
    if (ast->pointerBase->isArray || ast->pointerBase->isMap)
       return type(ast->pointerBase) + "&";
    return type(ast->pointerBase) + "*";
  }

  if (ast->isRuntimeSizedArray)
    return "std::span<" + type(ast->elementType) + ">";
  if (ast->isSlice)
    return "std::span<" + type(ast->elementType) + ">";
  if (ast->isArray) return type(ast->elementType);
  if (ast->isMap) {
    return "std::unordered_map<" + type(ast->keyType) + ", " +
           type(ast->elementType) +
           ", glang::DeepHash, glang::DeepEqual>";
  }
  if (ast->isTuple) {
    std::string result = "std::tuple<";
    for (size_t i = 0; i < ast->tupleElementTypes.size(); ++i) {
      if (i) result += ", ";
      result += type(ast->tupleElementTypes[i]);
    }
    return result + ">";
  }
  if (ast->isFunctionType) {
    std::string result = "std::function<" +
                         (ast->returnType ? type(ast->returnType) : "void") +
                         "(";
    for (size_t i = 0; i < ast->paramTypes.size(); ++i) {
      if (i) result += ", ";
      result += type(ast->paramTypes[i]);
    }
    return result + ")>";
  }
  const std::string& astName =
      ast->resolvedName.empty() ? ast->name : ast->resolvedName;
  std::string primitive = cppPrimitive(astName);
  if (!primitive.empty())
    return ast->isConst ? "const " + primitive : primitive;
  if (m_listTypes.count(astName) && ast->templateArgs.size() == 1) {
    return "std::vector<" + type(ast->templateArgs[0]) + ">";
  }
  if (m_lazyTypes.count(astName) && ast->templateArgs.size() == 1) {
    return "glang::Lazy<" + type(ast->templateArgs[0]) + ">";
  }
  if (m_coreTypes.count(astName) && ast->templateArgs.size() == 1) {
    return "std::shared_ptr<" + type(ast->templateArgs[0]) + ">";
  }
  if (!ast->templateArgs.empty()) {
    return identifier(cppSpecializedName(typeASTSpelling(ast)));
  }
  return identifier(cppSpecializedName(astName));
}

std::string CppCodeGen::declarator(TypePtr value,
                                   const std::string& name) const {
  TypePtr t = value ? value->underlyingType() : nullptr;
  if (!t) return "void " + name;
  if ((t->isFunction() || t->isClosure()) && t->isFunctionPointer) {
    std::string result =
        (t->returnType ? type(t->returnType) : "void") + " (*" + name + ")(";
    for (size_t i = 0; i < t->paramTypes.size(); ++i) {
      if (i) result += ", ";
      result += type(t->paramTypes[i]);
    }
    return result + ")";
  }
  if (t->isArray()) {
    return declarator(t->elementType,
                      name + "[" + std::to_string(t->arraySize) + "]");
  }
  if (t->isPointer()) {
    TypePtr base = t->pointerBase ? t->pointerBase->underlyingType() : nullptr;
    if (base && base->isArray()) {
      return declarator(base, "(*" + name + ")");
    }
    return type(t->pointerBase) + "* " + name;
  }
  return type(t) + " " + name;
}

std::string CppCodeGen::declarator(TypeASTPtr ast,
                                   const std::string& name) const {
  if (!ast) return "void " + name;
  if (ast->isFunctionPointer) {
    std::string result =
        (ast->returnType ? type(ast->returnType) : "void") + " (*" + name +
        ")(";
    for (size_t i = 0; i < ast->paramTypes.size(); ++i) {
      if (i) result += ", ";
      result += type(ast->paramTypes[i]);
    }
    return result + ")";
  }
  if (ast->isArray) {
    return declarator(ast->elementType,
                      name + "[" + std::to_string(ast->arraySize) + "]");
  }
  if (ast->isPointer) {
    if (ast->pointerBase && ast->pointerBase->isArray) {
      return declarator(ast->pointerBase, "(*" + name + ")");
    }
    return type(ast->pointerBase) + "* " + name;
  }
  return type(ast) + " " + name;
}

std::string CppCodeGen::structDeclaration(std::shared_ptr<StructDeclAST> decl) {
  if (!decl) return "";
  for (const auto& attr : decl->attributes) {
    if (attr.name == "core") return "";
  }
  if (!decl->typeParams.empty()) return "";
  std::ostringstream out;
  auto structName = identifier(cppSpecializedName(decl->name));

  out << "struct " << structName << " {\n";
  for (const auto& field : decl->fields) {
    out << "  " << declarator(field.typeAst, identifier(field.name))
        << "{};\n";
  }

  out << "  bool operator==(const " << structName
      << "& other) const {\n";
  for (const auto& field : decl->fields) {
    out << "    if (!glang::deep_equal(" << identifier(field.name)
        << ", other." << identifier(field.name) << ")) return false;\n";
  }
  out << "    return true;\n"
      << "  }\n";
  out << "  std::size_t glang_hash() const {\n"
      << "    std::size_t seed = 0;\n";
  for (const auto& field : decl->fields) {
    out << "    glang::hash_combine(seed, glang::deep_hash("
        << identifier(field.name) << "));\n";
  }
  out << "    return seed;\n"
      << "  }\n"
      << "};\n\n";
  return out.str();
}

std::string CppCodeGen::unionDeclaration(std::shared_ptr<UnionDeclAST> decl) {
  if (!decl || !decl->typeParams.empty()) return "";
  std::ostringstream out;
  auto unionName = identifier(cppSpecializedName(decl->name));
  out << "union " << unionName << " {\n";
  for (const auto& field : decl->fields) {
    out << "  " << declarator(field.typeAst, identifier(field.name)) << ";\n";
  }
  out << "  bool operator==(const " << unionName
      << "& other) const {\n"
      << "    return std::memcmp(this, &other, sizeof(" << unionName
      << ")) == 0;\n"
      << "  }\n"
      << "  std::size_t glang_hash() const {\n"
      << "    std::size_t seed = 0;\n"
      << "    const auto* bytes = reinterpret_cast<const unsigned char*>(this);\n"
      << "    for (std::size_t i = 0; i < sizeof(" << unionName
      << "); ++i) glang::hash_combine(seed, bytes[i]);\n"
      << "    return seed;\n"
      << "  }\n"
      << "};\n";
  return out.str();
}

std::string CppCodeGen::declaration(
    std::shared_ptr<FunctionDeclAST> function) {
  if (!function) return "";
  const bool isExtern =
      !function->body || hasFunctionAttribute(*function, "extern");
  const bool isCLinkage = isExtern && hasFunctionAttribute(*function, "c_abi");
  const bool isCVariadic =
      isExtern && !function->parameters.empty() &&
      function->parameters.back().isVariadic;
  std::string name =
      function->name == "main"
          ? "main"
          : identifier(function->mangledName.empty() ? function->name
                                                      : function->mangledName);
  std::ostringstream out;
  if (isExtern) out << "extern " << (isCLinkage ? "\"C\"" : "") << " ";
  if (function->name == "main") {
    out << "int main(";
  } else {
    out << type(function->returnTypeAst) << " " << name << "(";
  }
  for (size_t i = 0; i < function->parameters.size(); ++i) {
    if (i) out << ", ";
    const auto& param = function->parameters[i];
    if (isCVariadic && param.isVariadic) {
      out << "...";
      continue;
    }
    if (isCLinkage && param.typeAst && param.typeAst->isFunctionPointer) {
      out << declarator(param.typeAst, identifier(param.name));
      continue;
    }
    if (!param.isVariadic && param.typeAst && param.typeAst->isArray) {
      out << declarator(param.typeAst, identifier(param.name));
      continue;
    }
    std::string ptype = param.isVariadic && param.typeAst &&
                                param.typeAst->elementType
                            ? "std::vector<" +
                                  type(param.typeAst->elementType) + ">"
                            : type(param.typeAst);
    if (param.typeAst && !param.typeAst->isPointer &&
        m_coreTypes.count(param.typeAst->name) &&
        !m_listTypes.count(param.typeAst->name) &&
        !m_lazyTypes.count(param.typeAst->name)) {
      ptype = "const " + ptype + "&";
    }
    out << ptype << " " << identifier(param.name);
  }
  out << ")";
  return out.str();
}

std::string CppCodeGen::definition(
    std::shared_ptr<FunctionDeclAST> function) {
  if (!function || !function->body ||
      hasFunctionAttribute(*function, "extern")) {
    return "";
  }
  std::ostringstream out;
  out << declaration(function) << " {\n";
  const bool previousMainFunction = m_inMainFunction;
  m_inMainFunction = function->name == "main";
  if (auto body = std::dynamic_pointer_cast<BlockExprAST>(function->body)) {
    out << block(body, 1, true);
  } else if (function->name == "main") {
    out << "  " << expression(function->body) << ";\n";
    out << "  return 0;\n";
  } else {
    out << "  return " << expression(function->body) << ";\n";
  }
  m_inMainFunction = previousMainFunction;
  out << "}\n";
  return out.str();
}

std::string leftTrim(std::string& s) {
  s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
    return !std::isspace(ch);
  }));
  return s;
}


std::string rightTrim(std::string& s) {
  s.erase(std::find_if(s.begin(), s.end(), [](unsigned char ch) {
    return !std::isspace(ch);
  }), s.end());
  return s;
}

std::string trim(std::string &s) {
  auto r = rightTrim(s);
  return leftTrim(r);
}


std::string CppCodeGen::statement(StmtPtr stmt, int level) {
  if (!stmt) return "";
  const std::string pad = indent(level);

  if (auto sBinding = std::dynamic_pointer_cast<StructuralBindingStmtAST>(stmt)) {
      TypePtr structuralType =
          sBinding->initializer && sBinding->initializer->inferredType
              ? sBinding->initializer->inferredType->underlyingType()
              : nullptr;
      std::ostringstream out;

      if (structuralType && (structuralType->isArray() ||
                             structuralType->isSlice())) {
        const std::string qualifier = sBinding->isConst ? "const auto " : "auto ";
        if (auto literal = std::dynamic_pointer_cast<ArrayLiteralExprAST>(
                sBinding->initializer)) {
          for (size_t index = 0;
               index < sBinding->symbols.size() &&
               index < literal->elements.size();
               ++index) {
            out << pad << qualifier << identifier(sBinding->symbols[index])
                << " = " << expression(literal->elements[index]) << ";\n";
          }
          return out.str();
        }

        const std::string storage =
            "_glang_bind_" + std::to_string(m_nextArrayId++);
        out << pad << "auto&& " << storage << " = "
            << expression(sBinding->initializer) << ";\n";
        for (size_t index = 0; index < sBinding->symbols.size(); ++index) {
          out << pad << qualifier << identifier(sBinding->symbols[index])
              << " = " << storage << "[" << index << "];\n";
        }
        return out.str();
      }

      if (structuralType && structuralType->isUnion() &&
          !structuralType->fields.empty()) {
        const std::string storage =
            "_glang_bind_" + std::to_string(m_nextArrayId++);
        out << pad << "auto " << storage << " = "
            << expression(sBinding->initializer) << ";\n";
        for (size_t index = 0;
             index < sBinding->symbols.size() &&
             index < structuralType->fields.size();
             ++index) {
          out << pad << (sBinding->isConst ? "const auto " : "auto ")
              << identifier(sBinding->symbols[index]) << " = " << storage
              << "." << identifier(structuralType->fields[index].name)
              << ";\n";
        }
        return out.str();
      }

      out << pad << "auto [";
      for (size_t index = 0; index < sBinding->symbols.size(); ++index) {
        if (index) out << ", ";
        out << identifier(sBinding->symbols[index]);
      }
      out << "] = " << expression(sBinding->initializer) << ";\n";
      return out.str();
  }

  if (auto variable = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
    std::string t = type(variable->inferredType);
    std::string name = identifier(variable->name);
    if (variable->typeAst && variable->typeAst->isRuntimeSizedArray &&
        variable->inferredType && variable->inferredType->isSlice()) {
      std::string storage = "_glang_array_" + std::to_string(m_nextArrayId++);
      return pad + "std::vector<" +
             type(variable->typeAst->elementType) + "> " + storage + "(" +
             expression(variable->typeAst->arraySizeExpr) + ");\n" + pad +
             t + " " + name + "(" + storage + ");\n";
    }
    if (variable->inferredType && variable->inferredType->isArray()) {
      const std::string arrayDeclaration =
          declarator(variable->inferredType, name);
      if (std::dynamic_pointer_cast<ArrayLiteralExprAST>(
              variable->initializer)) {
        return pad + arrayDeclaration + " = " +
               expression(variable->initializer) + ";\n";
      }
      if (variable->initializer) {
        return pad + arrayDeclaration + "{};\n" + pad +
               "glang::array_copy(" + name + ", " +
               expression(variable->initializer) + ");\n";
      }
      return pad + arrayDeclaration + "{};\n";
    }
    if (variable->initializer &&
        std::dynamic_pointer_cast<ArrayLiteralExprAST>(variable->initializer) &&
        variable->inferredType && variable->inferredType->isSlice()) {
      return pad + "std::vector<" +
             type(variable->inferredType->elementType) + "> " + name +
             " = " + expression(variable->initializer) + ";\n";
    }
    if (variable->initializer) {
      std::string initializer = expression(variable->initializer);
      TypePtr sourceType = variable->initializer->inferredType
                               ? variable->initializer->inferredType
                                     ->underlyingType()
                               : nullptr;
      TypePtr targetType = variable->inferredType
                               ? variable->inferredType->underlyingType()
                               : nullptr;
      if (sourceType && targetType && sourceType->isPointer() &&
          targetType->isPointer() && sourceType->pointerBase &&
          sourceType->pointerBase->isVoid() && targetType->pointerBase &&
          !targetType->pointerBase->isVoid()) {
        initializer =
            "static_cast<" + t + ">(" + initializer + ")";
      }
      return pad + t + " " + name + " = " + initializer + ";\n";
    }
    return pad + t + " " + name + "{};\n";
  }
  if (auto ret = std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
    return pad + "return" +
           (ret->value ? " " + expression(ret->value)
                       : (m_inMainFunction ? " 0" : "")) +
           ";\n";
  }
  if (auto yield = std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
    return pad + "return" +
           (yield->value ? " " + expression(yield->value) : "") + ";\n";
  }
  if (auto defer = std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
    std::string name = "_glang_defer_" + std::to_string(m_nextDeferId++);
    return pad + "auto " + name + " = glang::make_scope_exit([&]() {\n" +
           statement(defer->deferredStmt, level + 1) + pad + "});\n";
  }
  if (auto brk = std::dynamic_pointer_cast<BreakStmtAST>(stmt)) {
    (void)brk;
    return pad + "break;\n";
  }
  if (std::dynamic_pointer_cast<ContinueStmtAST>(stmt)) {
    return pad + "continue;\n";
  }
  if (auto loop = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
    return pad + "while (" + expression(loop->condition) + ") " +
           statement(loop->body, level) ;
  }
  if (auto loop = std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
    return pad + "do " + statement(loop->body, level) + pad + "while (" +
           expression(loop->condition) + ");\n";
  }
  if (auto loop = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
    auto init = loop->init ? statement(loop->init, 0) : "";
    return pad + "for ( " + (loop->init ? init : " ;") + (loop->condition ? expression(loop->condition) : "") +
           "; " + (loop->post ? expression(loop->post) : "") + ") " +
           statement(loop->body, level);
  }
  if (auto exprStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
    if (auto scope = std::dynamic_pointer_cast<BlockExprAST>(exprStmt->expr);
        scope && scope->inferredType && scope->inferredType->isVoid()) {
      return block(scope, level);
    }
    if (auto ifExpr = std::dynamic_pointer_cast<IfExprAST>(exprStmt->expr)) {
      std::string result = pad + "if (" + expression(ifExpr->condition) + ") ";
      if (auto thenBlock =
              std::dynamic_pointer_cast<BlockExprAST>(ifExpr->thenBranch)) {
        result += block(thenBlock, level);
      } else {
        result += "{\n" + statement(
            std::make_shared<ExprStmtAST>(ifExpr->thenBranch->loc,
                                          ifExpr->thenBranch),
            level + 1) +
            pad + "}\n";
      }
      if (ifExpr->elseBranch) {
        result += pad + "else ";
        if (auto elseBlock =
                std::dynamic_pointer_cast<BlockExprAST>(ifExpr->elseBranch)) {
          result += block(elseBlock, level);
        } else {
          result += statement(
              std::make_shared<ExprStmtAST>(ifExpr->elseBranch->loc,
                                            ifExpr->elseBranch),
              level);
        }
      }
      return result;
    }
    return pad + expression(exprStmt->expr) + ";\n";
  }
  return "";
}

std::string CppCodeGen::block(std::shared_ptr<BlockExprAST> body, int level,
                              bool functionBody) {
  if (!body) return "{}\n";
  struct AddressTemporary {
    const ExprAST* expression;
    ExprPtr initializer;
    std::string name;
  };
  std::vector<AddressTemporary> addressTemporaries;
  std::function<void(ExprPtr)> collectExpression;
  std::function<void(StmtPtr)> collectStatement;
  collectStatement = [&](StmtPtr stmt) {
    if (!stmt) return;
    if (auto variable = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
      collectExpression(variable->initializer);
    } else if (auto binding =
                   std::dynamic_pointer_cast<StructuralBindingStmtAST>(stmt)) {
      collectExpression(binding->initializer);
    } else if (auto expression =
                   std::dynamic_pointer_cast<ExprStmtAST>(stmt)) {
      collectExpression(expression->expr);
    } else if (auto returned =
                   std::dynamic_pointer_cast<ReturnStmtAST>(stmt)) {
      collectExpression(returned->value);
    } else if (auto yielded =
                   std::dynamic_pointer_cast<YieldStmtAST>(stmt)) {
      collectExpression(yielded->value);
    } else if (auto deferred =
                   std::dynamic_pointer_cast<DeferStmtAST>(stmt)) {
      collectStatement(deferred->deferredStmt);
    } else if (auto loop = std::dynamic_pointer_cast<WhileStmtAST>(stmt)) {
      collectExpression(loop->condition);
      collectStatement(loop->body);
    } else if (auto loop = std::dynamic_pointer_cast<DoWhileStmtAST>(stmt)) {
      collectStatement(loop->body);
      collectExpression(loop->condition);
    } else if (auto loop = std::dynamic_pointer_cast<ForStmtAST>(stmt)) {
      collectStatement(loop->init);
      collectExpression(loop->condition);
      collectExpression(loop->post);
      collectStatement(loop->body);
    }
  };
  collectExpression = [&](ExprPtr current) {
    if (!current || std::dynamic_pointer_cast<BlockExprAST>(current) ||
        std::dynamic_pointer_cast<ClosureExprAST>(current)) {
      return;
    }
    if (auto node = std::dynamic_pointer_cast<UnaryExprAST>(current)) {
      if (node->op == "&" &&
          std::dynamic_pointer_cast<StructInitExprAST>(node->operand)) {
        std::string name =
            "_glang_address_temp_" +
            std::to_string(m_addressOfTemporaries.size());
        m_addressOfTemporaries[node.get()] = name;
        addressTemporaries.push_back({node.get(), node->operand, name});
      }
      collectExpression(node->operand);
    } else if (auto node = std::dynamic_pointer_cast<PostfixUnaryExprAST>(current)) {
      collectExpression(node->operand);
    } else if (auto node = std::dynamic_pointer_cast<MemberAccessExprAST>(current)) {
      collectExpression(node->object);
    } else if (auto node = std::dynamic_pointer_cast<CallExprAST>(current)) {
      collectExpression(node->callee);
      for (const auto& argument : node->arguments) collectExpression(argument);
    } else if (auto node =
                   std::dynamic_pointer_cast<StaticMethodCallExprAST>(current)) {
      for (const auto& argument : node->arguments) collectExpression(argument);
    } else if (auto node = std::dynamic_pointer_cast<AssignExprAST>(current)) {
      collectExpression(node->target);
      collectExpression(node->value);
    } else if (auto node = std::dynamic_pointer_cast<BinaryExprAST>(current)) {
      collectExpression(node->left);
      collectExpression(node->right);
    } else if (auto node = std::dynamic_pointer_cast<IndexExprAST>(current)) {
      collectExpression(node->target);
      collectExpression(node->index);
    } else if (auto node = std::dynamic_pointer_cast<SliceExprAST>(current)) {
      collectExpression(node->target);
      collectExpression(node->startExpr);
      collectExpression(node->endExpr);
    } else if (auto node =
                   std::dynamic_pointer_cast<StructInitExprAST>(current)) {
      for (const auto& field : node->fieldInits)
        collectExpression(field.second);
    } else if (auto node =
                   std::dynamic_pointer_cast<ArrayLiteralExprAST>(current)) {
      for (const auto& element : node->elements) collectExpression(element);
    } else if (auto node =
                   std::dynamic_pointer_cast<MapLiteralExprAST>(current)) {
      for (const auto& entry : node->entries) {
        collectExpression(entry.first);
        collectExpression(entry.second);
      }
    } else if (auto node =
                   std::dynamic_pointer_cast<TupleLiteralExprAST>(current)) {
      for (const auto& element : node->elements) collectExpression(element);
    } else if (auto node = std::dynamic_pointer_cast<IfExprAST>(current)) {
      collectExpression(node->condition);
      collectExpression(node->thenBranch);
      collectExpression(node->elseBranch);
    } else if (auto node = std::dynamic_pointer_cast<SwitchExprAST>(current)) {
      collectExpression(node->targetExpr);
      for (const auto& item : node->cases) {
        collectExpression(item.pattern);
        collectExpression(item.rangeEnd);
        collectExpression(item.body);
      }
    } else if (auto node = std::dynamic_pointer_cast<YieldExprAST>(current)) {
      collectExpression(node->yieldedExpr);
    } else if (auto node = std::dynamic_pointer_cast<CastExprAST>(current)) {
      collectExpression(node->expr);
    }
  };
  for (const auto& stmt : body->statements) collectStatement(stmt);
  collectExpression(body->yieldExpr);

  std::ostringstream out;
  if (!functionBody) out << indent(level) << "{\n";
  const int bodyLevel = functionBody ? level : level + 1;
  for (const auto& temporary : addressTemporaries) {
    out << indent(bodyLevel) << type(temporary.initializer->inferredType) << " "
        << temporary.name << "{};\n";
  }
  bool emittedYield = false;
  for (const auto& stmt : body->statements) {
    if (emittedYield) {
      continue;
    }
    if (body->yieldExpr) {
      if (auto exprStmt = std::dynamic_pointer_cast<ExprStmtAST>(stmt);
          exprStmt && exprStmt->expr.get() == body->yieldExpr.get()) {
        out << indent(bodyLevel) << "return " << expression(body->yieldExpr)
            << ";\n";
        emittedYield = true;
        continue;
      }
    }
    out << statement(stmt, bodyLevel);
  }
  bool endsWithReturn = false;
  if (!body->statements.empty()) {
    endsWithReturn =
        static_cast<bool>(std::dynamic_pointer_cast<ReturnStmtAST>(
            body->statements.back())) ||
        static_cast<bool>(std::dynamic_pointer_cast<YieldStmtAST>(
            body->statements.back()));
  }
  if (body->yieldExpr && !endsWithReturn && !emittedYield) {
    out << indent(bodyLevel) << "return " << expression(body->yieldExpr)
        << ";\n";
  }
  if (!functionBody) out << indent(level) << "}\n";
  for (const auto& temporary : addressTemporaries) {
    m_addressOfTemporaries.erase(temporary.expression);
  }
  return out.str();
}

std::string CppCodeGen::callArgument(ExprPtr argument, TypePtr parameterType,
                                     CallTemporaries& temporaries) {
  if (parameterType) {
    TypePtr parameter = parameterType->underlyingType();
    if (parameter && parameter->isArray()) {
      if (std::dynamic_pointer_cast<ArrayLiteralExprAST>(argument)) {
        const std::string name =
            "_glang_array_arg_" + std::to_string(m_nextArrayId++);
        temporaries.declarations.push_back(declarator(parameter, name) + " = " +
                                           expression(argument));
        return name;
      }
      if (argument && argument->inferredType) {
        TypePtr argumentType = argument->inferredType->underlyingType();
        if (argumentType && argumentType->isSlice()) {
          return expression(argument) + ".data()";
        }
      }
    }
    if (parameter && parameter->isSlice() &&
        std::dynamic_pointer_cast<ArrayLiteralExprAST>(argument)) {
      auto array = std::dynamic_pointer_cast<ArrayLiteralExprAST>(argument);
      const std::string elementType = type(parameter->elementType);
      if (array->elements.empty()) {
        return "std::span<" + elementType + ">()";
      }
      const std::string name =
          "_glang_slice_arg_" + std::to_string(m_nextArrayId++);
      // Materialize the literal as a raw C array so it works for every
      // element type, including `bool` (std::vector<bool> cannot back a
      // std::span and is therefore unusable here).
      std::ostringstream storage;
      storage << elementType << " " << name << "[" << array->elements.size()
              << "] = {";
      for (size_t item = 0; item < array->elements.size(); ++item) {
        if (item) storage << ", ";
        storage << expression(array->elements[item]);
      }
      storage << "}";
      temporaries.declarations.push_back(storage.str());
      return "std::span<" + elementType + ">(" + name + ")";
    }
  }
  return expression(argument);
}

std::string CppCodeGen::wrapCall(const std::string& invocation,
                                 const CallTemporaries& temporaries) {
  if (temporaries.declarations.empty()) return invocation;
  std::ostringstream out;
  out << "(" << lambdaCapture() << "() { ";
  for (const auto& declaration : temporaries.declarations) {
    out << declaration << "; ";
  }
  out << "return " << invocation << "; }())";
  return out.str();
}

std::string CppCodeGen::call(std::shared_ptr<CallExprAST> expr) {
  if (expr->usesBuiltinOperator) {
    auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr->callee);
    if (!id) return "";
    if (expr->operatorKind == "infix" && expr->arguments.size() == 2) {
      return "(" + expression(expr->arguments[0]) + " " + id->name + " " +
             expression(expr->arguments[1]) + ")";
    }
    if (expr->operatorKind == "prefix" && expr->arguments.size() == 1) {
      return "(" + id->name + expression(expr->arguments[0]) + ")";
    }
    if (expr->operatorKind == "postfix" && expr->arguments.size() == 1) {
      return "(" + expression(expr->arguments[0]) + ")" + id->name;
    }
  }

  if (auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr->callee)) {
    std::string intrinsic;
    if (id->name == "__list_push") intrinsic = "glang::list_push";
    if (id->name == "__list_length") intrinsic = "glang::list_length";
    if (id->name.rfind("__lazy_", 0) == 0) {
      intrinsic = "glang::" + id->name.substr(2);
    }
    auto hasIntrinsicSuffix = [&](const std::string& suffix) {
      return id->name == suffix ||
             (id->name.size() > suffix.size() &&
              id->name.compare(id->name.size() - suffix.size(),
                               suffix.size(), suffix) == 0);
    };
    const bool newBoxCall = hasIntrinsicSuffix("__new_box");
    const bool newBoxWithDeleterCall =
        hasIntrinsicSuffix("__new_box_with_deleter");
    const bool boxFromCall = hasIntrinsicSuffix("__box_from");
    const bool adoptBoxCall = hasIntrinsicSuffix("__adopt_box");

    auto boxTypeArgument = [&]() -> TypePtr {
      TypePtr result = expr->targetReturnType
                           ? expr->targetReturnType->underlyingType()
                           : (expr->inferredType
                                  ? expr->inferredType->underlyingType()
                                  : nullptr);
      if (result && result->typeArgs.size() == 1) {
        return result->typeArgs.front();
      }
      return nullptr;
    };

    if (newBoxCall) {
      TypePtr inner = boxTypeArgument();
      if (inner) {
        return "std::make_shared<" + type(inner) + ">()";
      }
    }
    if (newBoxWithDeleterCall && expr->arguments.size() == 1) {
      TypePtr inner = boxTypeArgument();
      if (inner) {
        return "std::shared_ptr<" + type(inner) + ">(new " + type(inner) +
               "(), " + expression(expr->arguments[0]) + ")";
      }
    }
    if (boxFromCall && expr->arguments.size() == 1) {
      TypePtr inner = boxTypeArgument();
      if (inner) {
        return "std::make_shared<" + type(inner) + ">(" +
               expression(expr->arguments[0]) + ")";
      }
    }
    if (adoptBoxCall && expr->arguments.size() == 2) {
      TypePtr inner = boxTypeArgument();
      if (inner) {
        return "std::shared_ptr<" + type(inner) + ">(" +
               expression(expr->arguments[0]) + ", " +
               expression(expr->arguments[1]) + ")";
      }
    }
    if (!intrinsic.empty()) {
      std::ostringstream result;
      result << intrinsic << "(";
      for (size_t i = 0; i < expr->arguments.size(); ++i) {
        if (i) result << ", ";
        result << expression(expr->arguments[i]);
      }
      return result.str() + ")";
    }
  }

  std::string name;
  if (!expr->targetMangledName.empty()) {
    name = identifier(expr->targetMangledName);
  } else if (auto id = std::dynamic_pointer_cast<IdentifierExprAST>(expr->callee)) {
    name = identifier(id->name);
    if (!expr->templateArgs.empty()) {
      name = identifier(mangleFunctionName(
          id->name, "", expr->targetParamTypes));
      name += "_G";
      for (const auto& typeArg : expr->templateArgs) {
        name += mangleTypeAST(typeArg);
      }
    }
  } else {
    name = expression(expr->callee);
  }

  std::vector<std::string> arguments;
  CallTemporaries temporaries;
  for (size_t i = 0; i < expr->arguments.size(); ++i) {
    ExprPtr argument = expr->arguments[i];
    const bool variadicArgument =
        expr->targetVariadic && i + 1 == expr->arguments.size() &&
        !expr->targetParamTypes.empty() &&
        i + 1 == expr->targetParamTypes.size();
    if (variadicArgument) {
      TypePtr paramType = expr->targetParamTypes.back();
      TypePtr elementType =
          paramType && (paramType->isSlice() || paramType->isArray())
              ? paramType->elementType
              : nullptr;
      if (elementType &&
          std::dynamic_pointer_cast<ArrayLiteralExprAST>(argument)) {
        auto array = std::dynamic_pointer_cast<ArrayLiteralExprAST>(argument);
        std::ostringstream packed;
        packed << "std::vector<" << type(elementType) << ">{";
        for (size_t item = 0; item < array->elements.size(); ++item) {
          if (item) packed << ", ";
          packed << expression(array->elements[item]);
        }
        arguments.push_back(packed.str() + "}");
        continue;
      }
      TypePtr argumentType = argument ? argument->inferredType : nullptr;
      if (elementType && argumentType &&
          (argumentType->isSlice() || argumentType->isArray())) {
        const std::string value = expression(argument);
        arguments.push_back("std::vector<" + type(elementType) + ">(" +
                            "std::begin(" + value + "), std::end(" + value +
                            "))");
        continue;
      }
    }
    TypePtr paramType =
        i < expr->targetParamTypes.size() ? expr->targetParamTypes[i] : nullptr;
    arguments.push_back(
        variadicArgument ? expression(argument)
                         : callArgument(argument, paramType, temporaries));
  }

  std::ostringstream invocation;
  invocation << name << "(";
  for (size_t i = 0; i < arguments.size(); ++i) {
    if (i) invocation << ", ";
    invocation << arguments[i];
  }
  invocation << ")";
  return wrapCall(invocation.str(), temporaries);
}

std::string CppCodeGen::cast(std::shared_ptr<CastExprAST> expr) {
  const std::string target = type(expr->inferredType);
  const std::string value = expression(expr->expr);
  if (expr->inferredType && expr->inferredType->isPointer() &&
      expr->inferredType->pointerBase &&
      expr->inferredType->pointerBase->isVoid() && expr->expr &&
      expr->expr->inferredType &&
      m_coreTypes.count(expr->expr->inferredType->name) &&
      !m_listTypes.count(expr->expr->inferredType->name) &&
      !m_lazyTypes.count(expr->expr->inferredType->name)) {
    return "static_cast<void*>(" + value + ".get())";
  }
  if (expr->inferredType && m_coreTypes.count(expr->inferredType->name) &&
      !m_listTypes.count(expr->inferredType->name) &&
      !m_lazyTypes.count(expr->inferredType->name) &&
      expr->inferredType->typeArgs.size() == 1) {
    return "std::shared_ptr<" + type(expr->inferredType->typeArgs[0]) +
           ">(static_cast<" + type(expr->inferredType->typeArgs[0]) + "*>(" +
           value + "), [](auto*) {})";
  }
  return "static_cast<" + target + ">(" + value + ")";
}

std::string CppCodeGen::expression(ExprPtr expr) {
  if (!expr) return "";
  if (auto value = std::dynamic_pointer_cast<IntegerLiteralExprAST>(expr))
    return value->value;
  if (auto value = std::dynamic_pointer_cast<FloatLiteralExprAST>(expr))
    return value->value;
  if (auto value = std::dynamic_pointer_cast<StringLiteralExprAST>(expr)) {
    return cppLiteral(value->value, '"');
  }
  if (auto value = std::dynamic_pointer_cast<CharLiteralExprAST>(expr))
    return cppLiteral(value->value, '\'');
  if (auto value = std::dynamic_pointer_cast<BoolLiteralExprAST>(expr))
    return value->value ? "true" : "false";
  if (std::dynamic_pointer_cast<NullLiteralExprAST>(expr)) return "nullptr";
  if (auto value = std::dynamic_pointer_cast<IdentifierExprAST>(expr)) {
    auto functions = m_functionNames.find(value->name);
    if (functions != m_functionNames.end()) {
      for (const auto& candidate : functions->second) {
        if (value->inferredType && candidate.second &&
            value->inferredType->equals(candidate.second)) {
          return identifier(candidate.first);
        }
      }
    }
    return identifier(value->name);
  }
  if (auto value = std::dynamic_pointer_cast<ScopedIdentifierExprAST>(expr)) {
    TypePtr scopedType =
        value->inferredType ? value->inferredType->underlyingType() : nullptr;
    if (scopedType && scopedType->isEnum()) {
      return identifier(scopedType->name) + "::" +
             identifier(value->memberName);
    }
    return scopedVariableIdentifier(value->scopeName + "::" +
                                    value->memberName);
  }
  if (auto value = std::dynamic_pointer_cast<BinaryExprAST>(expr)) {
    TypePtr leftType = value->left && value->left->inferredType
                           ? value->left->inferredType->underlyingType()
                           : nullptr;
    TypePtr rightType = value->right && value->right->inferredType
                            ? value->right->inferredType->underlyingType()
                            : nullptr;
    const bool sequenceComparison =
        (leftType && (leftType->isArray() || leftType->isSlice())) ||
        (rightType && (rightType->isArray() || rightType->isSlice()));
    if (sequenceComparison && (value->op == "==" || value->op == "!=")) {
      const std::string comparison = "glang::deep_equal(" +
                                     expression(value->left) + ", " +
                                     expression(value->right) + ")";
      return value->op == "==" ? comparison : "(!" + comparison + ")";
    }
    if (value->isOverloadedOperator && !value->targetMangledName.empty()) {
      CallTemporaries temporaries;
      const std::string leftArgument = callArgument(
          value->left,
          value->targetParamTypes.size() > 0 ? value->targetParamTypes[0]
                                             : nullptr,
          temporaries);
      const std::string rightArgument = callArgument(
          value->right,
          value->targetParamTypes.size() > 1 ? value->targetParamTypes[1]
                                             : nullptr,
          temporaries);
      return wrapCall(identifier(value->targetMangledName) + "(" +
                          leftArgument + ", " + rightArgument + ")",
                      temporaries);
    }
    return "(" + expression(value->left) + " " + value->op + " " +
           expression(value->right) + ")";
  }
  if (auto value = std::dynamic_pointer_cast<UnaryExprAST>(expr)) {
    if (value->op == "sizeof") {
      return "sizeof(" +
             (value->typeOperand && value->typeOperand->isArray
                  ? declarator(value->typeOperand, "")
                  : type(value->typeOperand)) +
             ")";
    }

    if (value->isOverloadedOperator && !value->targetMangledName.empty()) {
      CallTemporaries temporaries;
      const std::string argument = callArgument(
          value->operand,
          value->targetParamTypes.empty() ? nullptr
                                          : value->targetParamTypes[0],
          temporaries);
      return wrapCall(identifier(value->targetMangledName) + "(" + argument +
                          ")",
                      temporaries);
    }

    if (value->op == "&") {
      if (std::dynamic_pointer_cast<StructInitExprAST>(value->operand)) {
        auto temporary = m_addressOfTemporaries.find(value.get());
        if (temporary != m_addressOfTemporaries.end()) {
          return "(" + lambdaCapture() + "() -> " + type(value->inferredType) + " { " +
                 temporary->second + " = " + expression(value->operand) +
                 "; return &" + temporary->second + "; }())";
        }
        return "(new " + expression(value->operand) + ")";
      }
    }

    if (auto index_ast = std::dynamic_pointer_cast<IndexExprAST>(value->operand)) {
        auto target = index_ast->target;
        if (value->op == "&" && target->inferredType && target->inferredType->isHashMap()) {
            return "&" + expression(target) + "[" + expression(index_ast->index) + "]";
        }
    }


    return "(" + value->op + " "+ expression(value->operand) + ")";
  }

  if (auto value = std::dynamic_pointer_cast<PostfixUnaryExprAST>(expr)) {
    if (value->isOverloadedOperator && !value->targetMangledName.empty()) {
      CallTemporaries temporaries;
      const std::string argument = callArgument(
          value->operand,
          value->targetParamTypes.empty() ? nullptr
                                          : value->targetParamTypes[0],
          temporaries);
      return wrapCall(identifier(value->targetMangledName) + "(" + argument +
                          ")",
                      temporaries);
    }

    if (value->op == "++" || value->op == "--") {
      return "(" + expression(value->operand) + ")" + value->op;
    }
  }

  if (auto value = std::dynamic_pointer_cast<CallExprAST>(expr))
    return call(value);
  if (auto value = std::dynamic_pointer_cast<StaticMethodCallExprAST>(expr)) {
    std::string target = value->targetMangledName.empty()
                             ? value->targetType + "_" + value->methodName
                             : value->targetMangledName;
    std::ostringstream out;
    out << identifier(target) << "(";
    CallTemporaries temporaries;
    for (size_t i = 0; i < value->arguments.size(); ++i) {
      if (i) out << ", ";
      TypePtr paramType =
          i < value->targetParamTypes.size() ? value->targetParamTypes[i]
                                             : nullptr;
      out << callArgument(value->arguments[i], paramType, temporaries);
    }
    out << ")";
    return wrapCall(out.str(), temporaries);
  }
  if (auto value = std::dynamic_pointer_cast<AssignExprAST>(expr)) {
    if (auto index = std::dynamic_pointer_cast<IndexExprAST>(value->target);
        index && index->target && index->target->inferredType &&
        index->target->inferredType->isHashMap()) {
      if (value->op == "=") {
        return "glang::map_set(" + expression(index->target) + ", " +
               expression(index->index) + ", " + expression(value->value) +
               ")";
      }
      return "glang::map_set(" + expression(index->target) + ", " +
             expression(index->index) + ", std::get<0>(glang::map_get(" +
             expression(index->target) + ", " + expression(index->index) +
             ")) " + value->op.substr(0, value->op.size() - 1) + " " +
             expression(value->value) + ")";
    }
    std::string right = expression(value->value);
    TypePtr sourceType = value->value->inferredType
                             ? value->value->inferredType->underlyingType()
                             : nullptr;
    TypePtr targetType = value->target->inferredType
                             ? value->target->inferredType->underlyingType()
                             : nullptr;
    if (value->op == "=" && targetType && targetType->isArray()) {
      const std::string destination =
          "_glang_array_dst_" + std::to_string(m_nextArrayId++);
      std::ostringstream result;
      result << "(" << lambdaCapture() << "() -> auto& { auto& " << destination
             << " = " << expression(value->target) << "; ";
      if (std::dynamic_pointer_cast<ArrayLiteralExprAST>(value->value)) {
        result << "glang::array_fill(" << destination << ", "
               << expression(value->value) << "); ";
      } else {
        result << "glang::array_copy(" << destination << ", "
               << expression(value->value) << "); ";
      }
      result << "return " << destination << "; }())";
      return result.str();
    }
    if (sourceType && targetType && sourceType->isPointer() &&
        targetType->isPointer() && sourceType->pointerBase &&
        sourceType->pointerBase->isVoid() && targetType->pointerBase &&
        !targetType->pointerBase->isVoid()) {
      right = "static_cast<" + type(targetType) + ">(" + right + ")";
    }
    return expression(value->target) + " " + value->op + " " + right;
  }
  if (auto value = std::dynamic_pointer_cast<MemberAccessExprAST>(expr)) {
    TypePtr objectType = value->object ? value->object->inferredType : nullptr;
    if (value->memberName == "length" && objectType &&
        m_listTypes.count(objectType->name)) {
      return expression(value->object) + ".size()";
    }
    if (value->memberName == "length" && objectType &&
        (objectType->isArray() || objectType->isSlice())) {
      TypePtr resolvedType = objectType->underlyingType();
      if (resolvedType && resolvedType->isArray()) {
        return std::to_string(resolvedType->arraySize);
      }
      return expression(value->object) + ".size()";
    }

    if (objectType->isTuple()) {
        int index = std::stoul(value->memberName);
        return "std::get<" + std::to_string(index) + ">(" + expression(value->object) + ")";
    }
    const bool pointer =
        (objectType && objectType->isPointer()) ||
        (objectType && m_coreTypes.count(objectType->name) &&
         !m_listTypes.count(objectType->name) &&
         !m_lazyTypes.count(objectType->name));
    return expression(value->object) + (pointer ? "->" : ".") +
           identifier(value->memberName);
  }
  
  if (auto value = std::dynamic_pointer_cast<IndexExprAST>(expr)) {
    if (value->target && value->target->inferredType &&
        value->target->inferredType->isHashMap()) {
      return "glang::map_get(" + expression(value->target) + ", " +
             expression(value->index) + ")";
    }
    return expression(value->target) + "[" + expression(value->index) + "]";
  }

  if (auto value = std::dynamic_pointer_cast<SliceExprAST>(expr)) {
    std::string first = value->startExpr ? expression(value->startExpr) : "0";
    TypePtr targetType = value->target && value->target->inferredType
                             ? value->target->inferredType->underlyingType()
                             : nullptr;
    const bool targetIsArray = targetType && targetType->isArray();
    std::string last =
        value->endExpr
            ? expression(value->endExpr)
            : (targetIsArray
                   ? std::to_string(targetType->arraySize)
                   : expression(value->target) + ".size()");
    std::string data = expression(value->target) +
                       (targetIsArray ? "" : ".data()");
    return "std::span<" + type(value->inferredType->elementType) + ">(" +
           data + " + " + first + ", (" + last +
           ") - (" + first + "))";
  }
  if (auto value = std::dynamic_pointer_cast<StructInitExprAST>(expr)) {
    std::ostringstream out;
    TypePtr structType =
        value->inferredType ? value->inferredType->underlyingType() : nullptr;
    if (structType && structType->isUnion()) {
      if (value->fieldInits.empty()) return type(value->inferredType) + "{}";
      const auto& initializer = value->fieldInits.front();
      std::string fieldName = initializer.first;
      size_t fieldIndex = 0;
      bool resolvedIndex = false;
      if (fieldName.rfind("_pos_", 0) == 0) {
        fieldIndex =
            static_cast<size_t>(std::stoul(fieldName.substr(5)));
        resolvedIndex = true;
        if (fieldIndex < structType->fields.size()) {
          fieldName = structType->fields[fieldIndex].name;
        }
      } else {
        for (size_t i = 0; i < structType->fields.size(); ++i) {
          if (structType->fields[i].name == fieldName) {
            fieldIndex = i;
            resolvedIndex = true;
            break;
          }
        }
      }
      TypePtr fieldType = resolvedIndex && fieldIndex < structType->fields.size()
                              ? structType->fields[fieldIndex].type
                              : nullptr;
      if (fieldType && fieldType->isArray() &&
          !std::dynamic_pointer_cast<ArrayLiteralExprAST>(initializer.second)) {
        const std::string temporary =
            "_glang_union_" + std::to_string(m_nextArrayId++);
        return "(" + lambdaCapture() + "() -> " + type(value->inferredType) +
               " { " + type(value->inferredType) + " " + temporary + "{}; " +
               "glang::array_copy(" + temporary + "." +
               identifier(fieldName) + ", " + expression(initializer.second) +
               "); return " + temporary + "; }())";
      }
      return type(value->inferredType) + "{." + identifier(fieldName) +
             " = " + expression(initializer.second) + "}";
    }
    std::vector<ExprPtr> orderedFields(
        structType && structType->isStruct() ? structType->fields.size() : 0);
    for (const auto& initializer : value->fieldInits) {
      size_t fieldIndex = orderedFields.size();
      if (initializer.first.rfind("_pos_", 0) == 0) {
        fieldIndex = static_cast<size_t>(
            std::stoul(initializer.first.substr(5)));
      } else if (structType && structType->isStruct()) {
        for (size_t i = 0; i < structType->fields.size(); ++i) {
          if (structType->fields[i].name == initializer.first) {
            fieldIndex = i;
            break;
          }
        }
      }
      if (fieldIndex < orderedFields.size()) {
        orderedFields[fieldIndex] = initializer.second;
      } else if (orderedFields.empty() &&
                 initializer.first.rfind("_pos_", 0) == 0) {
        orderedFields.push_back(initializer.second);
      }
    }

    bool needsAssignmentBlock = false;
    if (structType && structType->isStruct()) {
      for (size_t i = 0; i < orderedFields.size(); ++i) {
        if (!orderedFields[i] || i >= structType->fields.size()) continue;
        TypePtr fieldType = structType->fields[i].type;
        if (fieldType && fieldType->isArray() &&
            !std::dynamic_pointer_cast<ArrayLiteralExprAST>(
                orderedFields[i])) {
          needsAssignmentBlock = true;
          break;
        }
      }
    }

    if (needsAssignmentBlock) {
      const std::string temporary =
          "_glang_struct_" + std::to_string(m_nextArrayId++);
      std::ostringstream block;
      block << "(" << lambdaCapture() << "() -> " << type(value->inferredType)
            << " { " << type(value->inferredType) << " " << temporary << "{}; ";
      for (size_t i = 0; i < orderedFields.size(); ++i) {
        if (!orderedFields[i] || i >= structType->fields.size()) continue;
        TypePtr fieldType = structType->fields[i].type;
        const std::string member =
            temporary + "." + identifier(structType->fields[i].name);
        if (fieldType && fieldType->isArray()) {
          if (std::dynamic_pointer_cast<ArrayLiteralExprAST>(
                  orderedFields[i])) {
            block << "glang::array_fill(" << member << ", "
                  << expression(orderedFields[i]) << "); ";
          } else {
            block << "glang::array_copy(" << member << ", "
                  << expression(orderedFields[i]) << "); ";
          }
        } else {
          block << member << " = " << expression(orderedFields[i]) << "; ";
        }
      }
      block << "return " << temporary << "; }())";
      return block.str();
    }

    out << type(value->inferredType) << "{";
    for (size_t i = 0; i < orderedFields.size(); ++i) {
      if (i) out << ", ";
      if (orderedFields[i]) out << expression(orderedFields[i]);
      else out << "{}";
    }
    return out.str() + "}";
  }
  if (auto value = std::dynamic_pointer_cast<IfExprAST>(expr)) {
    std::string retType = type(value->inferredType);
    std::string result = "(" + lambdaCapture() + "() -> " + retType +
                         " { if (" + expression(value->condition) +
                         ") { return " + expression(value->thenBranch) + "; } ";
    if (value->elseBranch)
      result += "return " + expression(value->elseBranch) + "; ";
    else
      result += "return " + retType + "{}; ";
    return result + "}())";
  }
  if (auto value = std::dynamic_pointer_cast<SwitchExprAST>(expr)) {
    std::string retType = type(value->inferredType);
    const bool hasRange = std::any_of(
        value->cases.begin(), value->cases.end(),
        [](const SwitchCase& item) { return item.rangeEnd != nullptr; });
    TypePtr targetType =
        value->targetExpr ? value->targetExpr->inferredType : nullptr;
    TypePtr normalizedTarget =
        targetType ? targetType->underlyingType() : nullptr;
    const bool targetIsCString = isCStringType(targetType);
    const bool targetIsAggregate =
        normalizedTarget &&
        (normalizedTarget->isArray() || normalizedTarget->isSlice() ||
         normalizedTarget->isTuple() || normalizedTarget->isStruct() ||
         normalizedTarget->isUnion() || normalizedTarget->isHashMap());
    const bool useIfLowering =
        hasRange || !isSwitchIntegerType(targetType);
    auto equality = [&](const std::string& target, ExprPtr pattern) {
      const std::string patternCode = expression(pattern);
      if (targetIsCString) {
        return "glang::c_string_equal(" + target + ", " + patternCode + ")";
      }
      if (targetIsAggregate) {
        return "glang::deep_equal(" + target + ", " + patternCode + ")";
      }
      return "(" + target + " == " + patternCode + ")";
    };

    std::string result = "(" + lambdaCapture() + "() -> " + retType + " { ";
    if (useIfLowering) {
      std::string target = "_glang_switch_" + std::to_string(m_nextSwitchId++);
      result += "auto " + target + " = " + expression(value->targetExpr) + "; ";
      bool firstCondition = true;
      ExprPtr defaultBody;
      for (const auto& branch : value->cases) {
        if (!branch.pattern) {
          defaultBody = branch.body;
          continue;
        }
        std::string condition;
        if (branch.rangeEnd) {
          condition = "(((" + target + ") >= (" +
                      expression(branch.pattern) + ")) && ((" + target +
                      ") <= (" + expression(branch.rangeEnd) + ")))";
        } else {
          condition = equality(target, branch.pattern);
        }
        result += firstCondition ? "if (" : "else if (";
        result += condition + ") { return " + expression(branch.body) +
                  "; } ";
        firstCondition = false;
      }
      if (defaultBody) {
        result += firstCondition ? "return " : "else { return ";
        result += expression(defaultBody);
        result += firstCondition ? "; " : "; } ";
      } else {
        result += "throw std::logic_error(\"non-exhaustive Glang switch\"); ";
      }
      return result + "}())";
    }

    result += "switch (" + expression(value->targetExpr) + ") { ";
    bool hasDefault = false;
    for (const auto& branch : value->cases) {
      if (branch.pattern) {
        result += "case " + expression(branch.pattern) + ": return " +
                  expression(branch.body) + "; ";
      } else {
        hasDefault = true;
        result += "default: return " + expression(branch.body) + "; ";
      }
    }
    result += "} ";
    if (!hasDefault) {
      result += "throw std::logic_error(\"non-exhaustive Glang switch\"); ";
    }
    return result + "}())";
  }
  if (auto value = std::dynamic_pointer_cast<BlockExprAST>(expr)) {
    std::ostringstream out;
    out << "(" << lambdaCapture() << "() -> " << type(value->inferredType)
        << " {\n";
    out << block(value, 1, true);
    out << "}())";
    return out.str();
  }
  if (auto value = std::dynamic_pointer_cast<CastExprAST>(expr)) return cast(value);
  if (auto value = std::dynamic_pointer_cast<ArrayLiteralExprAST>(expr)) {
    std::ostringstream out;
    const bool isSlice =
        value->inferredType && value->inferredType->isSlice();
    if (isSlice) {
      out << "std::vector<" << type(value->inferredType->elementType) << ">";
    }
    out << "{";
    for (size_t i = 0; i < value->elements.size(); ++i) {
      if (i) out << ", ";
      out << expression(value->elements[i]);
    }
    return out.str() + "}";
  }
  if (auto value = std::dynamic_pointer_cast<MapLiteralExprAST>(expr)) {
    std::ostringstream out;
    out << type(value->inferredType) << "{";
    for (size_t i = 0; i < value->entries.size(); ++i) {
      if (i) out << ", ";
      out << "{" << expression(value->entries[i].first) << ", "
          << expression(value->entries[i].second) << "}";
    }
    return out.str() + "}";
  }
  if (auto value = std::dynamic_pointer_cast<TupleLiteralExprAST>(expr)) {
    std::string result = "std::make_tuple(";
    for (size_t i = 0; i < value->elements.size(); ++i) {
      if (i) result += ", ";
      result += expression(value->elements[i]);
    }
    return result + ")";
  }
  if (auto value = std::dynamic_pointer_cast<ClosureExprAST>(expr)) {
    const bool prevMain = m_inMainFunction;
    m_inMainFunction = false;

    std::string result = lambdaCapture() + "(";
      for (size_t i = 0; i < value->params.size() ; ++i) {
      if (i) result += ", ";
      ClosureParam& param = value->params[i];
      result += declarator(param.typeAst, identifier(param.name));
    }
    result += ")\n";
    if (auto _block = std::dynamic_pointer_cast<BlockExprAST>(value->body)) {
        result += block(_block, 0, false);
    } else {
        result +=  "{\n" + expression(value->body) + "\n}\n";
    }
    m_inMainFunction = prevMain;
    return result;
  }

  if (auto value = std::dynamic_pointer_cast<YieldExprAST>(expr))
    return expression(value->yieldedExpr);
  return "";
}

std::string CppCodeGen::generate(const std::vector<ASTNodePtr>& nodes,
                                const std::vector<StmtPtr>& topStatements) {
    m_errors.clear();
    m_nextDeferId = 0;
    m_nextArrayId = 0;
    m_coreTypes.clear();
    m_listTypes.clear();
    m_lazyTypes.clear();
    m_functionNames.clear();
    std::ostringstream out;
    out << "// Generated by Glang C++ Backend\n"
        << "#include <algorithm>\n#include <cstddef>\n"
        << "#include <cstdint>\n#include <functional>\n#include <memory>\n"
        << "#include <string>\n#include <string_view>\n"
        << "#include <tuple>\n#include <unordered_map>\n#include <utility>\n"
        << "#include <span>\n#include <vector>\n#include <iterator>\n#include <type_traits>\n"
        << "#include <concepts>\n#include <cstring>\n#include <initializer_list>\n\n"
        << "#include <stdexcept>\n"
        << "#include <cstdio>\n\n"
        ;

    std::set<std::string> cppIncludes;
    for (const auto& node : nodes) {
        auto decl = std::dynamic_pointer_cast<DeclAST>(node);
        if (!decl) continue;
        for (const auto& attr : decl->attributes) {
            if (attr.name != "cpp_include") continue;
            for (const auto& arg : attr.args) {
                auto path =
                    std::dynamic_pointer_cast<StringLiteralExprAST>(arg.value);
                if (path && cppIncludes.insert(path->value).second) {
                    out << "#include \"" << path->value << "\"\n";
                }
            }
        }
    }
    if (!cppIncludes.empty()) out << "\n";

    out << "namespace glang {\n"
        << "template<class T> void list_push(std::vector<T>* list, T value) { list->push_back(std::move(value)); }\n"
        << "template<class T> int list_length(const std::vector<T>* list) { return static_cast<int>(list->size()); }\n"
        << "template <class Destination, class Source>\n"
        << "void array_copy(Destination& destination, const Source& source) {\n"
        << "  using Element = std::remove_reference_t<decltype(*std::begin(destination))>;\n"
        << "  const std::size_t count =\n"
        << "      std::min<std::size_t>(std::size(destination), std::size(source));\n"
        << "  if constexpr (std::is_trivially_copyable_v<Element>) {\n"
        << "    if (count != 0 && static_cast<const void*>(std::begin(destination)) !=\n"
        << "                          static_cast<const void*>(std::begin(source))) {\n"
        << "      std::memcpy(const_cast<void*>(static_cast<const void*>(\n"
        << "                      std::begin(destination))),\n"
        << "                  static_cast<const void*>(std::begin(source)),\n"
        << "                  count * sizeof(Element));\n"
        << "    }\n"
        << "  } else {\n"
        << "    std::copy_n(std::begin(source), count,\n"
        << "                const_cast<Element*>(std::begin(destination)));\n"
        << "  }\n"
        << "}\n"
        << "template <class T, std::size_t N, class U>\n"
        << "void array_fill(T (&destination)[N], std::initializer_list<U> values) {\n"
        << "  std::size_t index = 0;\n"
        << "  for (const auto& value : values) {\n"
        << "    if (index >= N) break;\n"
        << "    destination[index++] = value;\n"
        << "  }\n"
        << "}\n"
        << "}\n\n"
        << "namespace glang {\n"
        << "template <class F> class ScopeExit {\n"
        << " public:\n"
        << "  explicit ScopeExit(F f) : action_(std::move(f)) {}\n"
        << "  ScopeExit(const ScopeExit&) = delete;\n"
        << "  ScopeExit& operator=(const ScopeExit&) = delete;\n"
        << "  ~ScopeExit() { action_(); }\n"
        << " private:\n"
        << "  F action_;\n"
        << "};\n"
        << "template <class F> ScopeExit<F> make_scope_exit(F f) {\n"
        << "  return ScopeExit<F>(std::move(f));\n"
        << "}\n"
        << "}\n\n"
        << "namespace glang {\n"
        << "inline void hash_combine(std::size_t& seed, std::size_t value) noexcept {\n"
        << "  seed ^= value + 0x9e3779b97f4a7c15ULL + (seed << 6) + (seed >> 2);\n"
        << "}\n"
        << "template<class T> inline constexpr bool dependent_false = false;\n"
        << "template<class T> struct is_c_string : std::false_type {};\n"
        << "template<class T> struct is_c_string<T*> : std::bool_constant<std::is_same_v<std::remove_cv_t<T>, char>> {};\n"
        << "template<class T, std::size_t N> struct is_c_string<T[N]> : std::bool_constant<std::is_same_v<std::remove_cv_t<T>, char>> {};\n"
        << "template<class T> inline constexpr bool is_c_string_v = is_c_string<std::remove_cv_t<std::remove_reference_t<T>>>::value;\n"
        << "inline std::size_t c_string_hash(const char* value) {\n"
        << "  return value ? std::hash<std::string_view>{}(std::string_view(value)) : 0;\n"
        << "}\n"
        << "inline bool c_string_equal(const char* left, const char* right) {\n"
        << "  if (left == right) return true;\n"
        << "  return left && right && std::strcmp(left, right) == 0;\n"
        << "}\n"
        << "template<class T, std::size_t N> std::size_t deep_hash(const T (&value)[N]);\n"
        << "template<class T, class A> std::size_t deep_hash(const std::vector<T, A>& value);\n"
        << "template<class T, std::size_t E> std::size_t deep_hash(std::span<T, E> value);\n"
        << "template<class... T> std::size_t deep_hash(const std::tuple<T...>& value);\n"
        << "template<class K, class V, class H, class E, class A> std::size_t deep_hash(const std::unordered_map<K, V, H, E, A>& value);\n"
        << "template<class T, std::size_t N> bool deep_equal(const T (&left)[N], const T (&right)[N]);\n"
        << "template<class T, class A> bool deep_equal(const std::vector<T, A>& left, const std::vector<T, A>& right);\n"
        << "template<class T, std::size_t E1, std::size_t E2> bool deep_equal(std::span<T, E1> left, std::span<T, E2> right);\n"
        << "template<class... T> bool deep_equal(const std::tuple<T...>& left, const std::tuple<T...>& right);\n"
        << "template<class K, class V, class H, class E, class A> bool deep_equal(const std::unordered_map<K, V, H, E, A>& left, const std::unordered_map<K, V, H, E, A>& right);\n"
        << "template<class T> std::size_t deep_hash(const T& value) {\n"
        << "  using U = std::remove_cvref_t<T>;\n"
        << "  if constexpr (is_c_string_v<U>) {\n"
        << "    return c_string_hash(value);\n"
        << "  } else if constexpr (requires { std::hash<U>{}(value); }) {\n"
        << "    return std::hash<U>{}(value);\n"
        << "  } else if constexpr (requires { value.glang_hash(); }) {\n"
        << "    return value.glang_hash();\n"
        << "  } else {\n"
        << "    static_assert(dependent_false<U>, \"Glang hashmap key type needs a hash implementation\");\n"
        << "  }\n"
        << "}\n"
        << "template<class T, std::size_t N> std::size_t deep_hash(const T (&value)[N]) {\n"
        << "  std::size_t seed = 0;\n"
        << "  for (const auto& element : value) hash_combine(seed, deep_hash(element));\n"
        << "  hash_combine(seed, N);\n"
        << "  return seed;\n"
        << "}\n"
        << "template<class T, class A> std::size_t deep_hash(const std::vector<T, A>& value) {\n"
        << "  std::size_t seed = 0;\n"
        << "  for (const auto& element : value) hash_combine(seed, deep_hash(element));\n"
        << "  hash_combine(seed, value.size());\n"
        << "  return seed;\n"
        << "}\n"
        << "template<class T, std::size_t E> std::size_t deep_hash(std::span<T, E> value) {\n"
        << "  std::size_t seed = 0;\n"
        << "  for (const auto& element : value) hash_combine(seed, deep_hash(element));\n"
        << "  hash_combine(seed, value.size());\n"
        << "  return seed;\n"
        << "}\n"
        << "template<class... T> std::size_t deep_hash(const std::tuple<T...>& value) {\n"
        << "  std::size_t seed = 0;\n"
        << "  std::apply([&](const auto&... element) { (hash_combine(seed, deep_hash(element)), ...); }, value);\n"
        << "  return seed;\n"
        << "}\n"
        << "template<class K, class V, class H, class E, class A> std::size_t deep_hash(const std::unordered_map<K, V, H, E, A>& value) {\n"
        << "  std::size_t seed = value.size();\n"
        << "  std::size_t entries = 0;\n"
        << "  for (const auto& [key, mapped] : value) {\n"
        << "    std::size_t entry = 0;\n"
        << "    hash_combine(entry, deep_hash(key));\n"
        << "    hash_combine(entry, deep_hash(mapped));\n"
        << "    entries ^= entry;\n"
        << "  }\n"
        << "  hash_combine(seed, entries);\n"
        << "  return seed;\n"
        << "}\n"
        << "template<class K, class V, class H, class E, class A> bool deep_equal(const std::unordered_map<K, V, H, E, A>& left, const std::unordered_map<K, V, H, E, A>& right) {\n"
        << "  if (left.size() != right.size()) return false;\n"
        << "  for (const auto& [key, value] : left) {\n"
        << "    auto found = right.find(key);\n"
        << "    if (found == right.end() || !deep_equal(value, found->second)) return false;\n"
        << "  }\n"
        << "  return true;\n"
        << "}\n"
        << "template<class T> bool deep_equal(const T& left, const T& right) {\n"
        << "  if constexpr (is_c_string_v<T>) {\n"
        << "    return c_string_equal(left, right);\n"
        << "  } else if constexpr (requires { { left == right } -> std::convertible_to<bool>; }) {\n"
        << "    return left == right;\n"
        << "  } else {\n"
        << "    static_assert(dependent_false<T>, \"Glang hashmap key type needs equality comparison\");\n"
        << "  }\n"
        << "}\n"
        << "template<class T, std::size_t N> bool deep_equal(const T (&left)[N], const T (&right)[N]) {\n"
        << "  for (std::size_t i = 0; i < N; ++i) if (!deep_equal(left[i], right[i])) return false;\n"
        << "  return true;\n"
        << "}\n"
        << "template<class T, class A> bool deep_equal(const std::vector<T, A>& left, const std::vector<T, A>& right) {\n"
        << "  if (left.size() != right.size()) return false;\n"
        << "  for (std::size_t i = 0; i < left.size(); ++i) if (!deep_equal(left[i], right[i])) return false;\n"
        << "  return true;\n"
        << "}\n"
        << "template<class T, std::size_t E1, std::size_t E2> bool deep_equal(std::span<T, E1> left, std::span<T, E2> right) {\n"
        << "  if (left.size() != right.size()) return false;\n"
        << "  for (std::size_t i = 0; i < left.size(); ++i) if (!deep_equal(left[i], right[i])) return false;\n"
        << "  return true;\n"
        << "}\n"
        << "template<class... T> bool deep_equal(const std::tuple<T...>& left, const std::tuple<T...>& right) {\n"
        << "  return [&]<std::size_t... I>(std::index_sequence<I...>) { return (deep_equal(std::get<I>(left), std::get<I>(right)) && ...); }(std::index_sequence_for<T...>{});\n"
        << "}\n"
        << "struct DeepHash { template<class T> std::size_t operator()(const T& value) const { return deep_hash(value); } };\n"
        << "struct DeepEqual { template<class T> bool operator()(const T& left, const T& right) const { return deep_equal(left, right); } };\n"
        << "template<class Map, class Key> auto map_get(const Map& map, const Key& key) -> std::tuple<typename Map::mapped_type, bool> {\n"
        << "  auto found = map.find(key);\n"
        << "  if (found != map.end()) return {found->second, true};\n"
        << "  return {typename Map::mapped_type{}, false};\n"
        << "}\n"
        << "template<class Map, class Key, class Value> typename Map::mapped_type& map_set(Map& map, Key&& key, Value&& value) {\n"
        << "  return map.insert_or_assign(std::forward<Key>(key), std::forward<Value>(value)).first->second;\n"
        << "}\n"
        << "}\n\n"
        << "namespace glang {\n"
        << "template <class T>\n"
        << "class Lazy {\n"
        << " public:\n"
        << "  using element_type = T;\n"
        << "  using Next = std::function<bool(T&)>;\n"
        << "  Lazy() = default;\n"
        << "  explicit Lazy(Next next)\n"
        << "      : state_(std::make_shared<State>(State{std::move(next)})) {}\n"
        << "  bool next(T& value) const {\n"
        << "    if (!state_ || !state_->next) return false;\n"
        << "    return state_->next(value);\n"
        << "  }\n"
        << " private:\n"
        << "  struct State { Next next; };\n"
        << "  std::shared_ptr<State> state_;\n"
        << "};\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_of(std::function<bool(T&)> next) {\n"
        << "  return Lazy<T>(std::move(next));\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_from_vector(std::vector<T> values) {\n"
        << "  struct State {\n"
        << "    std::vector<T> values;\n"
        << "    std::size_t index = 0;\n"
        << "  };\n"
        << "  auto state = std::make_shared<State>();\n"
        << "  state->values = std::move(values);\n"
        << "  return lazy_of<T>([state](T& out) -> bool {\n"
        << "    if (state->index >= state->values.size()) return false;\n"
        << "    out = state->values[state->index++];\n"
        << "    return true;\n"
        << "  });\n"
        << "}\n"
        << "template <class U, std::size_t E>\n"
        << "Lazy<std::remove_cv_t<U>> lazy_from_span(std::span<U, E> values) {\n"
        << "  using T = std::remove_cv_t<U>;\n"
        << "  return lazy_from_vector<T>(std::vector<T>(values.begin(), values.end()));\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_from_list(std::vector<T> values) {\n"
        << "  return lazy_from_vector<T>(std::move(values));\n"
        << "}\n"
        << "inline Lazy<char> lazy_from_cstr(const char* text) {\n"
        << "  std::vector<char> values;\n"
        << "  if (text) {\n"
        << "    for (const char* cursor = text; *cursor != '\\0'; ++cursor) {\n"
        << "      values.push_back(*cursor);\n"
        << "    }\n"
        << "  }\n"
        << "  return lazy_from_vector<char>(std::move(values));\n"
        << "}\n"
        << "inline Lazy<int> lazy_range_step(int start, int end, int step) {\n"
        << "  if (step == 0) step = 1;\n"
        << "  struct State { int current; int end; int step; };\n"
        << "  auto state = std::make_shared<State>(State{start, end, step});\n"
        << "  return lazy_of<int>([state](int& out) -> bool {\n"
        << "    if (state->step > 0 ? state->current >= state->end\n"
        << "                        : state->current <= state->end) {\n"
        << "      return false;\n"
        << "    }\n"
        << "    out = state->current;\n"
        << "    state->current += state->step;\n"
        << "    return true;\n"
        << "  });\n"
        << "}\n"
        << "inline Lazy<int> lazy_range(int end) { return lazy_range_step(0, end, 1); }\n"
        << "inline Lazy<int> lazy_range(int start, int end) {\n"
        << "  return lazy_range_step(start, end, 1);\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "auto lazy_map(Lazy<T> source, F fn) {\n"
        << "  using U = std::invoke_result_t<F&, T>;\n"
        << "  return lazy_of<U>([source, fn = std::move(fn)](U& out) mutable -> bool {\n"
        << "    T value{};\n"
        << "    if (!source.next(value)) return false;\n"
        << "    out = fn(value);\n"
        << "    return true;\n"
        << "  });\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "Lazy<T> lazy_filter(Lazy<T> source, F predicate) {\n"
        << "  return lazy_of<T>(\n"
        << "      [source, predicate = std::move(predicate)](T& out) mutable -> bool {\n"
        << "        T value{};\n"
        << "        while (source.next(value)) {\n"
        << "          if (predicate(value)) {\n"
        << "            out = value;\n"
        << "            return true;\n"
        << "          }\n"
        << "        }\n"
        << "        return false;\n"
        << "      });\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_take(Lazy<T> source, int count) {\n"
        << "  auto remaining = std::make_shared<int>(count);\n"
        << "  return lazy_of<T>([source, remaining](T& out) -> bool {\n"
        << "    if (*remaining <= 0) return false;\n"
        << "    if (!source.next(out)) {\n"
        << "      *remaining = 0;\n"
        << "      return false;\n"
        << "    }\n"
        << "    --*remaining;\n"
        << "    return true;\n"
        << "  });\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_drop(Lazy<T> source, int count) {\n"
        << "  auto dropped = std::make_shared<bool>(false);\n"
        << "  return lazy_of<T>([source, dropped, count](T& out) -> bool {\n"
        << "    if (!*dropped) {\n"
        << "      T ignored{};\n"
        << "      for (int i = 0; i < count; ++i) {\n"
        << "        if (!source.next(ignored)) {\n"
        << "          *dropped = true;\n"
        << "          return false;\n"
        << "        }\n"
        << "      }\n"
        << "      *dropped = true;\n"
        << "    }\n"
        << "    return source.next(out);\n"
        << "  });\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "Lazy<T> lazy_take_while(Lazy<T> source, F predicate) {\n"
        << "  auto done = std::make_shared<bool>(false);\n"
        << "  return lazy_of<T>(\n"
        << "      [source, done, predicate = std::move(predicate)](T& out) mutable -> bool {\n"
        << "        if (*done) return false;\n"
        << "        T value{};\n"
        << "        if (!source.next(value)) {\n"
        << "          *done = true;\n"
        << "          return false;\n"
        << "        }\n"
        << "        if (!predicate(value)) {\n"
        << "          *done = true;\n"
        << "          return false;\n"
        << "        }\n"
        << "        out = value;\n"
        << "        return true;\n"
        << "      });\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "Lazy<T> lazy_drop_while(Lazy<T> source, F predicate) {\n"
        << "  auto dropped = std::make_shared<bool>(false);\n"
        << "  return lazy_of<T>(\n"
        << "      [source, dropped, predicate = std::move(predicate)](T& out) mutable -> bool {\n"
        << "        if (!*dropped) {\n"
        << "          T value{};\n"
        << "          while (source.next(value)) {\n"
        << "            if (!predicate(value)) {\n"
        << "              *dropped = true;\n"
        << "              out = value;\n"
        << "              return true;\n"
        << "            }\n"
        << "          }\n"
        << "          *dropped = true;\n"
        << "          return false;\n"
        << "        }\n"
        << "        return source.next(out);\n"
        << "      });\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_stride(Lazy<T> source, int step) {\n"
        << "  if (step < 1) step = 1;\n"
        << "  return lazy_of<T>([source, step](T& out) -> bool {\n"
        << "    if (!source.next(out)) return false;\n"
        << "    T ignored{};\n"
        << "    for (int i = 1; i < step; ++i) {\n"
        << "      if (!source.next(ignored)) break;\n"
        << "    }\n"
        << "    return true;\n"
        << "  });\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "Lazy<T> lazy_inspect(Lazy<T> source, F fn) {\n"
        << "  return lazy_of<T>(\n"
        << "      [source, fn = std::move(fn)](T& out) mutable -> bool {\n"
        << "        if (!source.next(out)) return false;\n"
        << "        fn(out);\n"
        << "        return true;\n"
        << "      });\n"
        << "}\n"
        << "template <class R>\n"
        << "struct lazy_sequence_source {\n"
        << "  using element_type =\n"
        << "      std::remove_cvref_t<decltype(*std::begin(std::declval<R&>()))>;\n"
        << "  static Lazy<element_type> make(R value) {\n"
        << "    std::vector<element_type> values(std::begin(value), std::end(value));\n"
        << "    return lazy_from_vector<element_type>(std::move(values));\n"
        << "  }\n"
        << "};\n"
        << "template <class U>\n"
        << "struct lazy_sequence_source<Lazy<U>> {\n"
        << "  using element_type = U;\n"
        << "  static Lazy<U> make(Lazy<U> value) { return value; }\n"
        << "};\n"
        << "template <>\n"
        << "struct lazy_sequence_source<const char*> {\n"
        << "  using element_type = char;\n"
        << "  static Lazy<char> make(const char* value) { return lazy_from_cstr(value); }\n"
        << "};\n"
        << "template <>\n"
        << "struct lazy_sequence_source<char*> {\n"
        << "  using element_type = char;\n"
        << "  static Lazy<char> make(char* value) { return lazy_from_cstr(value); }\n"
        << "};\n"
        << "template <class T, class F>\n"
        << "auto lazy_flat_map(Lazy<T> source, F fn) {\n"
        << "  using Result = std::remove_cvref_t<std::invoke_result_t<F&, T>>;\n"
        << "  using Source = lazy_sequence_source<Result>;\n"
        << "  using U = typename Source::element_type;\n"
        << "  struct State {\n"
        << "    Lazy<T> source;\n"
        << "    F fn;\n"
        << "    Lazy<U> inner;\n"
        << "    bool has_inner = false;\n"
        << "    State(Lazy<T> s, F f) : source(std::move(s)), fn(std::move(f)) {}\n"
        << "  };\n"
        << "  auto state = std::make_shared<State>(std::move(source), std::move(fn));\n"
        << "  return lazy_of<U>([state](U& out) mutable -> bool {\n"
        << "    while (true) {\n"
        << "      if (state->has_inner && state->inner.next(out)) return true;\n"
        << "      T value{};\n"
        << "      if (!state->source.next(value)) return false;\n"
        << "      state->inner = Source::make(state->fn(value));\n"
        << "      state->has_inner = true;\n"
        << "    }\n"
        << "  });\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<std::tuple<int, T>> lazy_enumerate(Lazy<T> source) {\n"
        << "  struct State {\n"
        << "    Lazy<T> source;\n"
        << "    int index = 0;\n"
        << "  };\n"
        << "  auto state = std::make_shared<State>();\n"
        << "  state->source = std::move(source);\n"
        << "  return lazy_of<std::tuple<int, T>>(\n"
        << "      [state](std::tuple<int, T>& out) -> bool {\n"
        << "        T value{};\n"
        << "        if (!state->source.next(value)) return false;\n"
        << "        out = std::make_tuple(state->index++, value);\n"
        << "        return true;\n"
        << "      });\n"
        << "}\n"
        << "template <class A, class B>\n"
        << "Lazy<std::tuple<A, B>> lazy_zip(Lazy<A> left, Lazy<B> right) {\n"
        << "  struct State {\n"
        << "    Lazy<A> left;\n"
        << "    Lazy<B> right;\n"
        << "  };\n"
        << "  auto state = std::make_shared<State>();\n"
        << "  state->left = std::move(left);\n"
        << "  state->right = std::move(right);\n"
        << "  return lazy_of<std::tuple<A, B>>(\n"
        << "      [state](std::tuple<A, B>& out) -> bool {\n"
        << "        A a{};\n"
        << "        B b{};\n"
        << "        if (!state->left.next(a)) return false;\n"
        << "        if (!state->right.next(b)) return false;\n"
        << "        out = std::make_tuple(a, b);\n"
        << "        return true;\n"
        << "      });\n"
        << "}\n"
        << "template <class T>\n"
        << "Lazy<T> lazy_chain(Lazy<T> first, Lazy<T> second) {\n"
        << "  struct State {\n"
        << "    Lazy<T> first;\n"
        << "    Lazy<T> second;\n"
        << "    bool second_active = false;\n"
        << "  };\n"
        << "  auto state = std::make_shared<State>();\n"
        << "  state->first = std::move(first);\n"
        << "  state->second = std::move(second);\n"
        << "  return lazy_of<T>([state](T& out) -> bool {\n"
        << "    if (!state->second_active) {\n"
        << "      if (state->first.next(out)) return true;\n"
        << "      state->second_active = true;\n"
        << "    }\n"
        << "    return state->second.next(out);\n"
        << "  });\n"
        << "}\n"
        << "template <class T>\n"
        << "std::vector<T> lazy_to_vector(Lazy<T> source) {\n"
        << "  std::vector<T> result;\n"
        << "  T value{};\n"
        << "  while (source.next(value)) result.push_back(value);\n"
        << "  return result;\n"
        << "}\n"
        << "template <class T, class U, class F>\n"
        << "U lazy_fold(Lazy<T> source, U initial, F fn) {\n"
        << "  U accumulator = std::move(initial);\n"
        << "  T value{};\n"
        << "  while (source.next(value)) accumulator = fn(std::move(accumulator), value);\n"
        << "  return accumulator;\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "T lazy_reduce(Lazy<T> source, F fn) {\n"
        << "  T value{};\n"
        << "  if (!source.next(value)) return T{};\n"
        << "  T accumulator = value;\n"
        << "  while (source.next(value)) accumulator = fn(std::move(accumulator), value);\n"
        << "  return accumulator;\n"
        << "}\n"
        << "template <class T>\n"
        << "int lazy_count(Lazy<T> source) {\n"
        << "  int total = 0;\n"
        << "  T value{};\n"
        << "  while (source.next(value)) ++total;\n"
        << "  return total;\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "int lazy_count_if(Lazy<T> source, F predicate) {\n"
        << "  int total = 0;\n"
        << "  T value{};\n"
        << "  while (source.next(value)) {\n"
        << "    if (predicate(value)) ++total;\n"
        << "  }\n"
        << "  return total;\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "bool lazy_any(Lazy<T> source, F predicate) {\n"
        << "  T value{};\n"
        << "  while (source.next(value)) {\n"
        << "    if (predicate(value)) return true;\n"
        << "  }\n"
        << "  return false;\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "bool lazy_all(Lazy<T> source, F predicate) {\n"
        << "  T value{};\n"
        << "  while (source.next(value)) {\n"
        << "    if (!predicate(value)) return false;\n"
        << "  }\n"
        << "  return true;\n"
        << "}\n"
        << "template <class T>\n"
        << "T lazy_sum(Lazy<T> source) {\n"
        << "  T total{};\n"
        << "  T value{};\n"
        << "  while (source.next(value)) total = total + value;\n"
        << "  return total;\n"
        << "}\n"
        << "template <class T>\n"
        << "std::tuple<T, bool> lazy_first(Lazy<T> source) {\n"
        << "  T value{};\n"
        << "  if (!source.next(value)) return std::make_tuple(T{}, false);\n"
        << "  return std::make_tuple(value, true);\n"
        << "}\n"
        << "template <class T>\n"
        << "T lazy_first_or(Lazy<T> source, T fallback) {\n"
        << "  T value{};\n"
        << "  if (!source.next(value)) return fallback;\n"
        << "  return value;\n"
        << "}\n"
        << "template <class T>\n"
        << "T lazy_last_or(Lazy<T> source, T fallback) {\n"
        << "  T value{};\n"
        << "  T last = fallback;\n"
        << "  while (source.next(value)) last = value;\n"
        << "  return last;\n"
        << "}\n"
        << "template <class T>\n"
        << "std::tuple<T, bool> lazy_nth(Lazy<T> source, int index) {\n"
        << "  if (index < 0) return std::make_tuple(T{}, false);\n"
        << "  T value{};\n"
        << "  for (int i = 0; i <= index; ++i) {\n"
        << "    if (!source.next(value)) return std::make_tuple(T{}, false);\n"
        << "  }\n"
        << "  return std::make_tuple(value, true);\n"
        << "}\n"
        << "template <class T, class F>\n"
        << "void lazy_for_each(Lazy<T> source, F fn) {\n"
        << "  T value{};\n"
        << "  while (source.next(value)) fn(value);\n"
        << "}\n"
        << "}\n\n"
        ;

    std::vector<std::shared_ptr<FunctionDeclAST>> functions;
    std::vector<std::shared_ptr<VarDeclStmtAST>> globalVariables;
    for (const auto& node : nodes) {
        if (auto decl = std::dynamic_pointer_cast<StructDeclAST>(node)) {
            for (const auto& attr : decl->attributes) {
                if (attr.name == "core") {
                  m_coreTypes.insert(decl->name);
                  if (decl->name == "List") m_listTypes.insert(decl->name);
                  if (decl->name == "Lazy") m_lazyTypes.insert(decl->name);
                }
            }
        }
    }
    std::set<std::string> forwardDeclaredStructs;
    for (const auto& node : nodes) {
        auto decl = std::dynamic_pointer_cast<StructDeclAST>(node);
        if (!decl || !decl->typeParams.empty() || decl->name == "std" ||
            std::any_of(decl->attributes.begin(), decl->attributes.end(),
                        [](const auto& attr) { return attr.name == "core"; })) {
            continue;
        }
        std::string structName = identifier(cppSpecializedName(decl->name));
        if (forwardDeclaredStructs.insert(structName).second) {
            out << "struct " << structName << ";\n";
        }
    }
    if (!forwardDeclaredStructs.empty()) out << "\n";
    for (const auto& node : nodes) {
        if (auto decl = std::dynamic_pointer_cast<StructDeclAST>(node)) {
            if (decl->name != "std") {
                out << structDeclaration(decl) << "\n";
            }
        } else if (auto decl = std::dynamic_pointer_cast<UnionDeclAST>(node)) {
            out << unionDeclaration(decl) << "\n";
        } else if (auto decl = std::dynamic_pointer_cast<EnumDeclAST>(node)) {
            out << "enum class " << identifier(decl->name) << " { ";
            for (size_t i = 0; i < decl->enumerators.size(); ++i) {
                if (i) out << ", ";
                out << identifier(decl->enumerators[i]);
            }
            out << " };\n\n";
        } else if (auto decl = std::dynamic_pointer_cast<FunctionDeclAST>(node)) {
            functions.push_back(decl);
            m_functionNames[decl->name].emplace_back(
                decl->mangledName.empty() ? decl->name : decl->mangledName,
                decl->inferredType);
        } else if (auto variable =
                   std::dynamic_pointer_cast<VarDeclStmtAST>(node)) {
            globalVariables.push_back(variable);
        }
    }
    auto isBoxIntrinsic = [](const std::string& name) {
      static const char* suffixes[] = {"__new_box", "__new_box_with_deleter",
                                       "__box_from", "__adopt_box"};
      for (const char* suffix : suffixes) {
        const std::string value = suffix;
        if (name == value ||
            (name.size() > value.size() &&
             name.compare(name.size() - value.size(), value.size(), value) ==
                 0)) {
          return true;
        }
      }
      return false;
    };
    for (const auto& function : functions) {
        if (isBoxIntrinsic(function->name)) continue;
        if (function->body && function->name != "main" &&
            !hasFunctionAttribute(*function, "extern")) {
            out << declaration(function) << ";\n";
        } else if (!function->body ||
                   hasFunctionAttribute(*function, "extern")) {
            out << declaration(function) << ";\n";
        }
    }
    std::vector<StmtPtr> runtimeTopStatements;
    std::set<const VarDeclStmtAST*> emittedGlobals;
    auto emitGlobalVariable = [&](const std::shared_ptr<VarDeclStmtAST>& variable) {
        if (!variable || !emittedGlobals.insert(variable.get()).second) return;
        struct GlobalInitializerScope {
            bool& flag;
            bool previous;
            explicit GlobalInitializerScope(bool& value)
                : flag(value), previous(value) {
                flag = true;
            }
            ~GlobalInitializerScope() { flag = previous; }
        } initializerScope(m_inGlobalInitializer);
        const std::string name =
            variable->name.find("::") == std::string::npos
                                     ? identifier(variable->name)
                                     : scopedVariableIdentifier(variable->name);
        if (variable->inferredType && variable->inferredType->isArray()) {
            out << (variable->isConst ? "const " : "")
                << declarator(variable->inferredType, name);
            if (std::dynamic_pointer_cast<ArrayLiteralExprAST>(
                    variable->initializer)) {
                out << " = " << expression(variable->initializer) << ";\n";
            } else if (variable->initializer) {
                out << "{};\n";
                const std::string initializerName =
                    "_glang_global_array_init_" +
                    std::to_string(m_nextArrayId++);
                out << "namespace { struct " << initializerName << " { "
                    << initializerName << "() { glang::array_copy(" << name
                    << ", " << expression(variable->initializer)
                    << "); } } " << initializerName << "_instance; }\n";
            } else {
                out << "{};\n";
            }
            return;
        }
        out << (variable->isConst ? "const " : "")
            << type(variable->inferredType) << " " << name;
        if (variable->initializer) {
            out << " = " << expression(variable->initializer);
        } else {
            out << "{}";
        }
        out << ";\n";
    };
    for (const auto& stmt : topStatements) {
        if (auto variable = std::dynamic_pointer_cast<VarDeclStmtAST>(stmt)) {
            emitGlobalVariable(variable);
        } else {
            runtimeTopStatements.push_back(stmt);
        }
    }
    for (const auto& variable : globalVariables) {
        emitGlobalVariable(variable);
    }
    if (!functions.empty()) out << "\n";
    for (const auto& function : functions) {
        if (function->body && !hasFunctionAttribute(*function, "extern")) {
            out << definition(function) << "\n";
        }
    }
    if (!runtimeTopStatements.empty()) {
        out << "int main() {\n";
        const bool previousMainFunction = m_inMainFunction;
        m_inMainFunction = true;
        for (const auto& stmt : runtimeTopStatements) out << statement(stmt, 1);
        m_inMainFunction = previousMainFunction;
        out << "  return 0;\n}\n";
    }
    return out.str();
}

}  // namespace Glang
