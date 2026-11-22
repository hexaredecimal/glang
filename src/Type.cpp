#include "compiler/Type.hpp"

#include <cctype>
#include <unordered_map>

namespace Glang {

namespace {

TypePtr substituteType(
    const Type* type,
    const std::map<std::string, TypePtr>& typeBindings,
    std::unordered_map<const Type*, TypePtr>& substitutedTypes) {
    if (!type) return nullptr;

    if (type->kind == TypeKind::GenericParam) {
        auto binding = typeBindings.find(type->name);
        if (binding != typeBindings.end() && binding->second) {
            return binding->second;
        }
    }

    auto existing = substitutedTypes.find(type);
    if (existing != substitutedTypes.end()) return existing->second;

    auto result = std::make_shared<Type>(*type);
    substitutedTypes.emplace(type, result);
    result->pointerBase =
        substituteType(type->pointerBase.get(), typeBindings, substitutedTypes);
    result->elementType =
        substituteType(type->elementType.get(), typeBindings, substitutedTypes);
    result->keyType =
        substituteType(type->keyType.get(), typeBindings, substitutedTypes);
    result->returnType =
        substituteType(type->returnType.get(), typeBindings, substitutedTypes);
    result->aliasTarget =
        substituteType(type->aliasTarget.get(), typeBindings, substitutedTypes);

    for (size_t i = 0; i < type->typeArgs.size(); ++i) {
        result->typeArgs[i] = substituteType(
            type->typeArgs[i].get(), typeBindings, substitutedTypes);
    }
    for (size_t i = 0; i < type->fields.size(); ++i) {
        result->fields[i].type = substituteType(
            type->fields[i].type.get(), typeBindings, substitutedTypes);
    }
    for (size_t i = 0; i < type->paramTypes.size(); ++i) {
        result->paramTypes[i] = substituteType(
            type->paramTypes[i].get(), typeBindings, substitutedTypes);
    }
    for (size_t i = 0; i < type->tupleElementTypes.size(); ++i) {
        result->tupleElementTypes[i] = substituteType(
            type->tupleElementTypes[i].get(), typeBindings, substitutedTypes);
    }
    return result;
}

}  // namespace

TypePtr Type::makePrimitive(std::string name) {
    auto t = std::make_shared<Type>(TypeKind::Primitive, name);
    return t;
}

TypePtr Type::makePointer(TypePtr base, bool isConst) {
    auto t = std::make_shared<Type>(TypeKind::Pointer);
    t->pointerBase = base;
    t->isConst = isConst;
    return t;
}

TypePtr Type::makeArray(TypePtr elemType, int size) {
    auto t = std::make_shared<Type>(TypeKind::Array);
    t->elementType = elemType;
    t->arraySize = size;
    return t;
}

TypePtr Type::makeSlice(TypePtr elemType) {
    auto t = std::make_shared<Type>(TypeKind::Slice);
    t->elementType = elemType;
    return t;
}

TypePtr Type::makeHashMap(TypePtr keyType, TypePtr valueType) {
    auto t = std::make_shared<Type>(TypeKind::HashMap);
    t->keyType = keyType;
    t->elementType = valueType;
    return t;
}

TypePtr Type::makeGenericParam(std::string name) {
    return std::make_shared<Type>(TypeKind::GenericParam, name);
}

TypePtr Type::makeStruct(std::string name, std::vector<TypePtr> typeArgs) {
    auto t = std::make_shared<Type>(TypeKind::Struct, name);
    t->typeArgs = std::move(typeArgs);
    return t;
}

TypePtr Type::makeUnion(std::string name, std::vector<TypePtr> typeArgs) {
    auto t = std::make_shared<Type>(TypeKind::Union, name);
    t->typeArgs = std::move(typeArgs);
    return t;
}

TypePtr Type::makeEnum(std::string name, std::vector<std::string> enums) {
    auto t = std::make_shared<Type>(TypeKind::Enum, name);
    t->enumerators = std::move(enums);
    return t;
}

TypePtr Type::makeFunction(std::vector<TypePtr> params, TypePtr ret) {
    auto t = std::make_shared<Type>(TypeKind::Function);
    t->paramTypes = std::move(params);
    t->returnType = std::move(ret);
    return t;
}

TypePtr Type::makeClosure(std::vector<TypePtr> params, TypePtr ret) {
    auto t = std::make_shared<Type>(TypeKind::Closure);
    t->paramTypes = std::move(params);
    t->returnType = std::move(ret);
    return t;
}

TypePtr Type::makeTuple(std::vector<TypePtr> elementTypes) {
    auto t = std::make_shared<Type>(TypeKind::Tuple);
    t->tupleElementTypes = std::move(elementTypes);
    return t;
}

TypePtr Type::makeAlias(const std::string& aliasName, TypePtr target) {
    auto t = std::make_shared<Type>(TypeKind::Alias, aliasName);
    t->aliasTarget = target;
    return t;
}

TypePtr Type::makeUnknown() {
    return std::make_shared<Type>(TypeKind::Unknown, "auto");
}

TypePtr Type::makeError() {
    return std::make_shared<Type>(TypeKind::Error, "<type-error>");
}

TypePtr Type::underlyingType() const {
    const Type* current = this;
    while (current && current->kind == TypeKind::Alias && current->aliasTarget) {
        current = current->aliasTarget.get();
    }
    if (!current) return nullptr;
    return std::make_shared<Type>(*current);
}

std::string Type::toString() const {
    if (!this) return "unknown";
    // If alias, prefer to show alias name with underlying type for clarity
    if (kind == TypeKind::Alias && aliasTarget) {
        std::string base = aliasTarget->toString();
        if (isConst) return std::string("const ") + name;
        return name ;
    }

    std::string res;
    if (isConst) res += "const ";

    switch (kind) {
        case TypeKind::Primitive:
        case TypeKind::GenericParam:
        case TypeKind::Enum:
        case TypeKind::Unknown:
        case TypeKind::Error:
            res += name;
            break;

        case TypeKind::Pointer:
            res += (pointerBase ? pointerBase->toString() : "void") + "*";
            break;

        case TypeKind::Array:
            res += (elementType ? elementType->toString() : "?") + "[" + std::to_string(arraySize) + "]";
            break;

        case TypeKind::Slice:
            res += (elementType ? elementType->toString() : "?") + "[]";
            break;

        case TypeKind::HashMap:
            res += (elementType ? elementType->toString() : "?") + "[" + (keyType ? keyType->toString() : "?") + "]";
            break;

        case TypeKind::Struct:
        case TypeKind::Union: {
            res += name;
            if (!typeArgs.empty()) {
                res += "<";
                for (size_t i = 0; i < typeArgs.size(); ++i) {
                    if (i > 0) res += ", ";
                    res += typeArgs[i] ? typeArgs[i]->toString() : "?";
                }
                res += ">";
            }
            break;
        }

        case TypeKind::Function:
        case TypeKind::Closure: {
            res += "(";
            for (size_t i = 0; i < paramTypes.size(); ++i) {
                if (i > 0) res += ", ";
                res += paramTypes[i] ? paramTypes[i]->toString() : "?";
            }
            res += ")" + (returnType ? returnType->toString() : "void");
            break;
        }

        case TypeKind::Tuple: {
            res += "(";
            for (size_t i = 0; i < tupleElementTypes.size(); ++i) {
                if (i > 0) res += ", ";
                res += tupleElementTypes[i] ? tupleElementTypes[i]->toString() : "?";
            }
            res += ")";
            break;
        }
        default:
            res += name;
            break;
    }
    return res;
}

bool Type::equals(const TypePtr& other) const {
    if (!this && !other) return true;
    if (!this || !other) return false;
    // Unwrap aliases for equality checks
    if (kind == TypeKind::Alias && aliasTarget) return aliasTarget->equals(other);
    if (other->kind == TypeKind::Alias && other->aliasTarget) return equals(other->aliasTarget);
    if (kind != other->kind) return false;

    if (kind == TypeKind::Primitive || kind == TypeKind::GenericParam || kind == TypeKind::Enum) {
        return name == other->name;
    }
    if (kind == TypeKind::Pointer) {
        return pointerBase && other->pointerBase && pointerBase->equals(other->pointerBase);
    }
    if (kind == TypeKind::Array) {
        return arraySize == other->arraySize && elementType && other->elementType && elementType->equals(other->elementType);
    }
    if (kind == TypeKind::Slice) {
        return elementType && other->elementType && elementType->equals(other->elementType);
    }
    if (kind == TypeKind::HashMap) {
        return keyType && other->keyType && keyType->equals(other->keyType) &&
               elementType && other->elementType && elementType->equals(other->elementType);
    }
    if (kind == TypeKind::Struct || kind == TypeKind::Union) {
        if (name != other->name) return false;
        if (typeArgs.size() != other->typeArgs.size()) return false;
        for (size_t i = 0; i < typeArgs.size(); ++i) {
            if (!typeArgs[i] || !other->typeArgs[i]) {
                if (typeArgs[i] != other->typeArgs[i]) return false;
            } else if (!typeArgs[i]->equals(other->typeArgs[i])) return false;
        }
        return true;
    }
    if (kind == TypeKind::Function || kind == TypeKind::Closure) {
        if (paramTypes.size() != other->paramTypes.size()) return false;
        for (size_t i = 0; i < paramTypes.size(); ++i) {
            if (!paramTypes[i] || !other->paramTypes[i]) {
                if (paramTypes[i] != other->paramTypes[i]) return false;
            } else if (!paramTypes[i]->equals(other->paramTypes[i])) return false;
        }
        if (!returnType || !other->returnType) return returnType == other->returnType;
        return returnType->equals(other->returnType);
    }
    if (kind == TypeKind::Tuple) {
        if (tupleElementTypes.size() != other->tupleElementTypes.size()) return false;
        for (size_t i = 0; i < tupleElementTypes.size(); ++i) {
            if (!tupleElementTypes[i] || !other->tupleElementTypes[i]) {
                if (tupleElementTypes[i] != other->tupleElementTypes[i]) return false;
            } else if (!tupleElementTypes[i]->equals(other->tupleElementTypes[i])) return false;
        }
        return true;
    }
    return true;
}

TypePtr Type::substitute(
    const std::map<std::string, TypePtr>& typeBindings) const {
  std::unordered_map<const Type*, TypePtr> substitutedTypes;
  return substituteType(this, typeBindings, substitutedTypes);
}

std::string mangleType(TypePtr type) {
    if (!type) return "v";
    auto encodeName = [](const std::string& name) {
        std::string encoded;
        for (char c : name) {
            if (std::isalnum(static_cast<unsigned char>(c)) || c == '_') {
                encoded += c;
            } else {
                encoded += '_';
            }
        }
        if (encoded.empty()) return std::string("anon");
        if (std::isdigit(static_cast<unsigned char>(encoded.front()))) {
            encoded.insert(encoded.begin(), '_');
        }
        return encoded;
    };
    switch (type->kind) {
        case TypeKind::Alias:
            return mangleType(type->aliasTarget);
        case TypeKind::Primitive: {
            if (type->name == "int") return "i";
            if (type->name == "uint") return "u";
            if (type->name == "bool") return "b";
            if (type->name == "char") return "c";
            if (type->name == "uchar") return "uc";
            if (type->name == "short") return "s";
            if (type->name == "ushort") return "us";
            if (type->name == "long") return "l";
            if (type->name == "ulong") return "ul";
            if (type->name == "float") return "f";
            if (type->name == "double") return "d";
            if (type->name == "string") return "str";
            if (type->name == "void") return "v";
            return type->name;
        }
        case TypeKind::Pointer:
            return "P" + mangleType(type->pointerBase);
        case TypeKind::Array:
            return "A" + std::to_string(type->arraySize) + "_" + mangleType(type->elementType);
        case TypeKind::Slice:
            return "Sl_" + mangleType(type->elementType);
        case TypeKind::Struct:
        case TypeKind::Union: {
            std::string res =
                (type->kind == TypeKind::Struct ? "S_" : "U_") +
                encodeName(type->name);
            if (!type->typeArgs.empty()) {
                res += "_G" + std::to_string(type->typeArgs.size());
                for (const auto& arg : type->typeArgs) {
                    res += "_" + mangleType(arg);
                }
            }
            return res;
        }
        case TypeKind::GenericParam:
            return "G_" + encodeName(type->name);
        case TypeKind::Enum:
            return "E_" + encodeName(type->name);
        case TypeKind::HashMap:
            return "Map_" + mangleType(type->keyType) + "_" +
                   mangleType(type->elementType);
        case TypeKind::Function:
        case TypeKind::Closure: {
            std::string res = "Fn_";
            for (const auto& p : type->paramTypes) {
                res += mangleType(p) + "_";
            }
            res += mangleType(type->returnType);
            return res;
        }
        case TypeKind::Tuple: {
            std::string res = "Tup_";
            for (const auto& t : type->tupleElementTypes) {
                res += mangleType(t) + "_";
            }
            return res;
        }
        default:
            return type->name.empty() ? "unk" : encodeName(type->name);
    }
}

std::string mangleFunctionName(const std::string& name, const std::string& ownerType, const std::vector<TypePtr>& paramTypes) {
    if (name == "main" && ownerType.empty()) {
        return "main";
    }

    auto encodeName = [](const std::string& value) {
        static const std::map<std::string, std::string> symbolWords = {
            {"|", "pipe"},        {">", "greaterthan"},
            {"<", "lessthan"},    {"=", "equal"},
            {"!", "exclamation"}, {"+", "plus"},
            {"-", "minus"},       {"*", "star"},
            {"/", "slash"},       {"%", "percent"},
            {"^", "caret"},       {"&", "ampersand"},
            {"~", "tilde"},       {"?", "question"},
            {":", "colon"},       {".", "dot"},
            {"@", "at"},          {"$", "dollar"},
            {"#", "hash"},        {"\\", "backslash"},
            {"`", "backtick"}};
        std::string result;
        for (size_t i = 0; i < value.size(); ++i) {
            const unsigned char c = static_cast<unsigned char>(value[i]);
            if (std::isalnum(c) || c == '_') {
                result += static_cast<char>(c);
                continue;
            }
            std::string symbol(1, static_cast<char>(c));
            auto word = symbolWords.find(symbol);
            if (word != symbolWords.end()) {
                if (!result.empty() && result.back() != '_') result += '_';
                result += word->second;
            } else {
                if (!result.empty() && result.back() != '_') result += '_';
                result += "u" + std::to_string(static_cast<unsigned int>(c));
            }
        }
        if (result.empty()) result = "operator";
        return result;
    };

    std::string encodedName = encodeName(name);
    std::string mangled;
    if (!ownerType.empty()) {
        mangled = ownerType + "_" + encodedName;
    } else {
        mangled = encodedName;
    }

    if (paramTypes.empty()) {
        mangled += "_v";
    } else {
        for (const auto& p : paramTypes) {
            mangled += "_" + mangleType(p);
        }
    }
    return mangled;
}

}  // namespace Glang
