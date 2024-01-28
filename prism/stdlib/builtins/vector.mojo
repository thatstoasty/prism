from ._list import list
from ._hash import HashableCollectionElement
from ._dict import StringKey


fn reverse[T: CollectionElement](vector: DynamicVector[T]) -> DynamicVector[T]:
    var reversed = DynamicVector[T]()
    for i in range(vector.size - 1, -1, -1):
        reversed.push_back(vector[i])
    return reversed


fn reverse_in_place[T: CollectionElement](inout vector: DynamicVector[T]) raises:
    for i in range(vector.size // 2):
        let mirror_i = vector.size - 1 - i
        let tmp = vector[i]
        vector[i] = vector[mirror_i]
        vector[mirror_i] = tmp


fn contains(vector: DynamicVector[String], value: String) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


fn contains(vector: DynamicVector[StringLiteral], value: StringLiteral) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


fn contains(vector: list[String], value: String) raises -> Bool:
    for item in vector:
        if item == value:
            return True
    return False


fn contains(vector: list[StringLiteral], value: StringLiteral) raises -> Bool:
    for item in vector:
        if item == value:
            return True
    return False


fn contains(vector: list[StringKey], value: StringKey) raises -> Bool:
    for item in vector:
        if item == value:
            return True
    return False


fn to_string(vector: DynamicVector[String]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += vector[i]
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: DynamicVector[Flag]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += vector[i].__str__()
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: list[String]) raises -> String:
    var result = String("[")
    for i in range(len(vector)):
        result += vector[i]
        if i < len(vector) - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: DynamicVector[Command]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += vector[i].__str__()
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result
