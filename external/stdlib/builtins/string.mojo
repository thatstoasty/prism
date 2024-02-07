from ..builtins._generic_list import list

alias _ALL_WHITESPACES = " \t\n\r\x0b\f"


fn __string__mul__(input_string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += input_string
    return result


fn rjust(input_string: String, width: Int, fillchar: String = " ") raises -> String:
    if len(fillchar) != 1:
        raise Error(" The fill character must be exactly one character long")
    let extra = width - len(input_string)
    return __string__mul__(fillchar, extra) + input_string


fn ljust(input_string: String, width: Int, fillchar: String = " ") raises -> String:
    if len(fillchar) != 1:
        raise Error(" The fill character must be exactly one character long")
    let extra = width - len(input_string)
    return input_string + __string__mul__(fillchar, extra)


fn endswith(
    input_string: String, suffix: String, start: Int = 0, owned end: Int = -1
) raises -> Bool:
    if end == -1:
        end = len(input_string)

    if end < start:
        raise Error("The end index must be greater than or equal to the start index")

    if end - start < len(suffix):
        return False

    return input_string[end - len(suffix) : end] == suffix


fn startswith(
    input_string: String, prefix: String, start: Int = 0, owned end: Int = -1
) raises -> Bool:
    if end == -1:
        end = len(input_string)

    if end < start:
        raise Error("The end index must be greater than or equal to the start index")

    if end - start < len(prefix):
        return False

    return input_string[start : start + len(prefix)] == prefix


fn split(
    input_string: String, sep: String = " ", owned maxsplit: Int = -1
) raises -> list[String]:
    """The separator can be multiple characters long."""
    var result = list[String]()
    if maxsplit == 0:
        result.append(input_string)
        return result
    if maxsplit < 0:
        maxsplit = len(input_string)

    if not sep:
        return list[String].from_string(input_string)[0:maxsplit]

    var output = list[String]()
    var start = 0
    var split_count = 0

    for end in range(len(input_string) - len(sep) + 1):
        if input_string[end : end + len(sep)] == sep:
            output.append(input_string[start:end])
            start = end + len(sep)
            split_count += 1

            if maxsplit > 0 and split_count >= maxsplit:
                break

    output.append(input_string[start:])
    return output


fn join(separator: String, iterable: list[String]) raises -> String:
    var result: String = ""
    for i in range(iterable.__len__()):
        result += iterable[i]
        if i != iterable.__len__() - 1:
            result += separator
    return result


fn replace(input_string: String, old: String, new: String, count: Int = -1) -> String:
    if count == 0:
        return input_string

    var output: String = ""
    var start = 0
    var split_count = 0

    for end in range(len(input_string) - len(old) + 1):
        if input_string[end : end + len(old)] == old:
            output += input_string[start:end] + new
            start = end + len(old)
            split_count += 1

            if count >= 0 and split_count >= count and count >= 0:
                break

    output += input_string[start:]
    return output


fn removeprefix(input_string: String, prefix: String) raises -> String:
    if startswith(input_string, prefix):
        return input_string[len(prefix) :]
    return input_string


fn removesuffix(input_string: String, suffix: String) raises -> String:
    if endswith(input_string, suffix):
        return input_string[: -len(suffix)]
    return input_string


fn expandtabs(input_string: String, tabsize: Int = 8) -> String:
    return replace(input_string, "\t", __string__mul__(" ", tabsize))


fn strip(input_string: String, chars: String = _ALL_WHITESPACES) -> String:
    let lstrip_index = _lstrip_index(input_string, chars)
    let rstrip_index = _rstrip_index(input_string, chars)
    return input_string[lstrip_index:rstrip_index]


fn lstrip(input_string: String, chars: String = _ALL_WHITESPACES) -> String:
    return input_string[_lstrip_index(input_string, chars) :]


fn rstrip(input_string: String, chars: String = _ALL_WHITESPACES) -> String:
    return input_string[: _rstrip_index(input_string, chars)]


fn _lstrip_index(input_string: String, chars: String) -> Int:
    for i in range(len(input_string)):
        if not (__str_contains__(input_string[i], chars)):
            return i
    return len(input_string)


fn _rstrip_index(input_string: String, chars: String) -> Int:
    for i in range(len(input_string) - 1, -1, -1):
        if not (__str_contains__(input_string[i], chars)):
            return i + 1
    return 0


fn __str_contains__(smaller_string: String, bigger_string: String) -> Bool:
    if len(smaller_string) > len(bigger_string):
        return False
    for i in range(len(bigger_string) - len(smaller_string) + 1):
        if smaller_string == bigger_string[i : i + len(smaller_string)]:
            return True
    return False
