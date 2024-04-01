from memory._arc import Arc


fn contains(vector: List[String], value: String) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


fn contains(vector: List[StringLiteral], value: StringLiteral) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


fn to_string(vector: List[String]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += vector[i]
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: List[Flag]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += str(vector[i])
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: List[Arc[Flag]]) -> String:
    var result = String("[")
    for i in range(vector.size):
        var flag = vector[i]
        result += str(flag[])
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: List[Arc[Command]]) -> String:
    var result = String("[")
    for i in range(vector.size):
        var item = vector[i]
        result += item[].name
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn join(separator: String, iterable: List[String]) raises -> String:
    var result: String = ""
    for i in range(len(iterable)):
        result += iterable[i]
        if i != len(iterable) - 1:
            result += separator
    return result
