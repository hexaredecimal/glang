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
    static TypePtr makeUnknown();
    static TypePtr makeError();

    bool isPointer() const { return kind == TypeKind::Pointer; }
    bool isPrimitive() const { return kind == TypeKind::Primitive; }
    bool isVoid() const { return kind == TypeKind::Primitive && name == "void"; }
    bool isArray() const { return kind == TypeKind::Array; }
    bool isSlice() const { return kind == TypeKind::Slice; }
    bool isHashMap() const { return kind == TypeKind::HashMap; }
    bool isStruct() const { return kind == TypeKind::Struct; }
    bool isUnion() const { return kind == TypeKind::Union; }
    bool isEnum() const { return kind == TypeKind::Enum; }
    bool isGenericParam() const { return kind == TypeKind::GenericParam; }
    bool isFunction() const { return kind == TypeKind::Function; }
    bool isClosure() const { return kind == TypeKind::Closure; }
    bool isTuple() const { return kind == TypeKind::Tuple; }
    bool isUnknown() const { return kind == TypeKind::Unknown; }

    std::string toString() const;
    bool equals(const TypePtr& other) const;

    TypePtr substitute(const std::map<std::string, TypePtr>& typeBindings) const;
};

std::string mangleType(TypePtr type);
std::string mangleFunctionName(const std::string& name, const std::string& ownerType, const std::vector<TypePtr>& paramTypes);

}  // namespace Glang

#endif
