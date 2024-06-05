from memory.arc import Arc
from collections.vector import InlinedFixedVector


trait EqualityComparableCollectionElement(EqualityComparable, CollectionElement):
    pass


fn contains[T: EqualityComparableCollectionElement](vector: List[T], value: T) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


fn to_string[T: StringableCollectionElement](vector: List[T]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += str(vector[i])
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string[T: StringableCollectionElement](vector: List[Arc[T]]) -> String:
    var result = String("[")
    for i in range(vector.size):
        var flag = vector[i]
        result += str(flag[])
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn join[T: StringableCollectionElement](separator: String, iterable: List[T]) -> String:
    var result: String = ""
    for i in range(len(iterable)):
        result += str(iterable[i])
        if i != len(iterable) - 1:
            result += separator
    return result
