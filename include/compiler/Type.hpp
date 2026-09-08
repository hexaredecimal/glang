#ifndef COMPILER_TYPE_HPP
#define COMPILER_TYPE_HPP

#include <string>
#include <vector>
#include <memory>
#include <map>

namespace Glang {

enum class TypeKind {
    Primitive,
    Pointer,
    Array,
    Slice,
    HashMap,
    GenericParam,
    Struct,
    Union,
    Enum,
    Function,
    Closure,
    Tuple,
    Alias,
    Unknown,
    Error
};

class Type;
using TypePtr = std::shared_ptr<Type>;

class Type {
public:
    TypeKind kind;
    std::string name;  // Note:  Primitive name, generic param name, or
                       // struct/union/enum name
    bool isConst{false};

    // Note:  Pointer type details
    TypePtr pointerBase{nullptr};

    // Note:  Array, Slice, HashMap details
    TypePtr elementType{nullptr};  // Note:  Element type for Array/Slice, or
                                   // Value type for HashMap
    TypePtr keyType{nullptr};      // Key type for HashMap
    int arraySize{0};              // Size for Sized Array

    // Note:  Generic type arguments
    // e.g. List<int>
    std::vector<TypePtr> typeArgs;

    // Note:  Struct / Union fields
    struct Field {
        std::string name;
        TypePtr type;
    };
    std::vector<Field> fields;

    // Note:  Enum enumerators
    std::vector<std::string> enumerators;

    // Note:  Function / Closure details
    std::vector<TypePtr> paramTypes;
    TypePtr returnType{nullptr};

    // Note:  Tuple details
    std::vector<TypePtr> tupleElementTypes;

    // Note: Alias target (if this Type is an alias)
    TypePtr aliasTarget{nullptr};

    Type(TypeKind k, std::string n = "") : kind(k), name(std::move(n)) {}

    static TypePtr makePrimitive(std::string name);
    static TypePtr makePointer(TypePtr base, bool isConst = false);
    static TypePtr makeArray(TypePtr elemType, int size);
    static TypePtr makeSlice(TypePtr elemType);
    static TypePtr makeHashMap(TypePtr keyType, TypePtr valueType);
    static TypePtr makeGenericParam(std::string name);
    static TypePtr makeStruct(std::string name, std::vector<TypePtr> typeArgs = {});
    static TypePtr makeUnion(std::string name, std::vector<TypePtr> typeArgs = {});
    static TypePtr makeEnum(std::string name, std::vector<std::string> enums = {});
    static TypePtr makeFunction(std::vector<TypePtr> params, TypePtr ret);
    static TypePtr makeClosure(std::vector<TypePtr> params, TypePtr ret);
    static TypePtr makeTuple(std::vector<TypePtr> elementTypes);
    static TypePtr makeAlias(const std::string& aliasName, TypePtr target);
    static TypePtr makeUnknown();
    static TypePtr makeError();

    bool isPointer() const { return kind == TypeKind::Pointer || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isPointer()); }
    bool isPrimitive() const { return kind == TypeKind::Primitive || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isPrimitive()); }
    bool isVoid() const { return (kind == TypeKind::Primitive && name == "void") || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isVoid()); }
    bool isArray() const { return kind == TypeKind::Array || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isArray()); }
    bool isSlice() const { return kind == TypeKind::Slice || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isSlice()); }
    bool isHashMap() const { return kind == TypeKind::HashMap || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isHashMap()); }
    bool isStruct() const { return kind == TypeKind::Struct || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isStruct()); }
    bool isUnion() const { return kind == TypeKind::Union || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isUnion()); }
    bool isEnum() const { return kind == TypeKind::Enum || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isEnum()); }
    bool isGenericParam() const { return kind == TypeKind::GenericParam || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isGenericParam()); }
    bool isFunction() const { return kind == TypeKind::Function || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isFunction()); }
    bool isClosure() const { return kind == TypeKind::Closure || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isClosure()); }
    bool isTuple() const { return kind == TypeKind::Tuple || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isTuple()); }
    bool isUnknown() const { return kind == TypeKind::Unknown || (kind == TypeKind::Alias && aliasTarget && aliasTarget->isUnknown()); }

    TypePtr underlyingType() const;
    std::string toString() const;
    bool equals(const TypePtr& other) const;

    TypePtr substitute(const std::map<std::string, TypePtr>& typeBindings) const;
};

std::string mangleType(TypePtr type);
std::string mangleFunctionName(const std::string& name, const std::string& ownerType, const std::vector<TypePtr>& paramTypes);

}  // namespace Glang

#endif
