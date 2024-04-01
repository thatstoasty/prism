fn copy[
    T: CollectionElement
](inout target: List[T], source: List[T], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        target: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(len(source)):
        if len(target) <= i + start:
            target.append(source[i])
        else:
            target[i + start] = source[i]
        count += 1

    return count


fn copy(inout target: Bytes, source: Bytes, start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        target: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    # If trying to set a value outside of the bounds of the buffer, use append instead. It will resize the buffer before setting the value.
    for i in range(len(source)):
        if i + start < target.size():
            target[i + start] = source[i]
        else:
            target.append(source[i])
        count += 1

    return count


fn cap(buffer: Bytes) -> Int:
    """Returns the capacity of the buffer.

    Args:
        buffer: The buffer to get the capacity of.
    """
    return buffer.capacity()


fn cap[T: CollectionElement](iterable: List[T]) -> Int:
    """Returns the capacity of the List.

    Args:
        iterable: The List to get the capacity of.
    """
    return iterable.capacity
