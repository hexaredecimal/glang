#include "compiler/Type.hpp"

namespace Glang {

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
            res += ") -> " + (returnType ? returnType->toString() : "void");
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
  if (!this) return nullptr;

  if (kind == TypeKind::GenericParam) {
    auto it = typeBindings.find(name);
    if (it != typeBindings.end() && it->second) {
      return it->second;
    }
  }
  if (kind == TypeKind::Pointer) {
    auto subBase =
        pointerBase ? pointerBase->substitute(typeBindings) : nullptr;
    return makePointer(subBase, isConst);
  }
  if (kind == TypeKind::Array) {
    auto subElem =
        elementType ? elementType->substitute(typeBindings) : nullptr;
    return makeArray(subElem, arraySize);
  }
  if (kind == TypeKind::Slice) {
    auto subElem =
        elementType ? elementType->substitute(typeBindings) : nullptr;
    return makeSlice(subElem);
  }
  if (kind == TypeKind::HashMap) {
    auto subKey = keyType ? keyType->substitute(typeBindings) : nullptr;
    auto subVal = elementType ? elementType->substitute(typeBindings) : nullptr;
    return makeHashMap(subKey, subVal);
  }
  if (kind == TypeKind::Struct || kind == TypeKind::Union) {
    std::vector<TypePtr> newArgs;
    for (const auto& arg : typeArgs) {
      newArgs.push_back(arg ? arg->substitute(typeBindings) : nullptr);
    }
    auto res = (kind == TypeKind::Struct) ? makeStruct(name, newArgs)
                                          : makeUnion(name, newArgs);
    res->fields = fields;  // copy layout
    return res;
  }
  if (kind == TypeKind::Function || kind == TypeKind::Closure) {
    std::vector<TypePtr> newParams;
    for (const auto& p : paramTypes) {
      newParams.push_back(p ? p->substitute(typeBindings) : nullptr);
    }
    auto newRet = returnType ? returnType->substitute(typeBindings) : nullptr;
    return (kind == TypeKind::Function) ? makeFunction(newParams, newRet)
                                        : makeClosure(newParams, newRet);
  }
  if (kind == TypeKind::Tuple) {
    std::vector<TypePtr> newElems;
    for (const auto& e : tupleElementTypes) {
      newElems.push_back(e ? e->substitute(typeBindings) : nullptr);
    }
    return makeTuple(newElems);
  }
  if (kind == TypeKind::Alias) {
    TypePtr subTarget =
        aliasTarget ? aliasTarget->substitute(typeBindings) : nullptr;
    auto res = makeAlias(name, subTarget);
    res->isConst = isConst;
    return res;
  }
  return std::make_shared<Type>(*this);
}

std::string mangleType(TypePtr type) {
    if (!type) return "v";
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
            return "S_" + type->name;
        case TypeKind::Union:
            return "U_" + type->name;
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
            return type->name.empty() ? "unk" : type->name;
    }
}

std::string mangleFunctionName(const std::string& name, const std::string& ownerType, const std::vector<TypePtr>& paramTypes) {
    if (name == "main" && ownerType.empty()) {
        return "main";
    }


    std::string mangled;
    if (!ownerType.empty()) {
        mangled = ownerType + "_" + name;
    } else {
        mangled = name;
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
