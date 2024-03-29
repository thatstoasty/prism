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


fn contains(vector: CommandMap, value: String) -> Bool:
    for i in vector.keys():
        if i[].s == value:
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
        result += vector[i].__str__()
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_string(vector: List[Command]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += vector[i].name
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn join(separator: String, iterable: List[String]) raises -> String:
    var result: String = ""
    for i in range(iterable.__len__()):
        result += iterable[i]
        if i != iterable.__len__() - 1:
            result += separator
    return result


fn get_slice[T: CollectionElement](vector: List[T], limits: Slice) -> List[T]:
    # TODO: Specifying no end to the span sets span end to this super large int for some reason.
    # Set it to len of the vector if that happens. Otherwise, if end is just too large in general, throw OOB error.

    # TODO: If no end was given, then it defaults to that large int.
    # Accidentally including the 0 (null) characters will mess up strings due to null termination. __str__ expects the exact length of the string from self.write_position.
    var end = limits.end
    if limits.end == 9223372036854775807:
        end = len(vector)

    var new = List[T]()
    for i in range(limits.start, end, limits.step):
        new.append(vector[i])

    return new