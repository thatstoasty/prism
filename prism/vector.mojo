from memory.arc import Arc


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
