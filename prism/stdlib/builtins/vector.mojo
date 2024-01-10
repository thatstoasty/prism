from collections.vector import DynamicVector
from ._list import list
from ._hash import HashableCollectionElement
from ._dict import HashableStr


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


fn contains(vector: list[HashableStr], value: HashableStr) raises -> Bool:
    for item in vector:
        if item == value:
            return True
    return False


fn main():
    var vector = DynamicVector[String]()
    vector.push_back("a")
    vector.push_back("b")
    vector.push_back("c")

    let reversed = reverse(vector)

    for i in range(reversed.size):
        print(reversed[i])
