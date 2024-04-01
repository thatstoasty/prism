from .errors import panic

alias Byte = Int8


@value
struct Bytes(Stringable, Sized, CollectionElement):
    """A mutable sequence of Bytes. Behaves like the python version.

    Note that some_bytes[i] returns an Int8.
    some_bytes *= 2 modifies the sequence in-place. Same with +=.

    Also __setitem__ is available, meaning you can do some_bytes[7] = 105 or
    even some_bytes[7] = some_other_byte (the latter must be only one byte long).
    """

    var _vector: List[Int8]
    var write_position: Int

    fn __init__(inout self, size: Int = 0):
        self.write_position = 0
        if size != 0:
            self._vector = List[Int8](capacity=size)
            for i in range(size):
                self._vector.append(0)
        else:
            self._vector = List[Int8]()

    fn __init__(inout self, owned vector: List[Int8]):
        self.write_position = len(vector)
        self._vector = vector

    fn __init__(inout self, *strs: String):
        self._vector = List[Int8]()
        var total_length = 0
        for string in strs:
            self._vector.extend(string[].as_bytes())
            total_length += len(string[])

        self.write_position = total_length

    fn __len__(self) -> Int:
        return self.write_position

    fn size(self) -> Int:
        """Returns the position of the last byte written to Bytes since it is 0 initialized.
        """
        return len(self._vector)

    fn resize(inout self, new_size: Int):
        """Resizes the Bytes to the new size. If the new size is larger than the current size, the new bytes are 0 initialized.
        """
        self._vector.resize(new_size, 0)

        # If the internal vector was resized to a smaller size than what was already written, the write position should be moved back.
        if new_size < self.write_position:
            self.write_position = new_size

    fn available(self) -> Int:
        return len(self._vector) - self.write_position

    fn __getitem__(self, index: Int) -> Int8:
        return self._vector[index]

    fn __getitem__(self, limits: Slice) -> Self:
        # TODO: Specifying no end to the span sets span end to this super large int for some reason.
        # Set it to len of the vector if that happens. Otherwise, if end is just too large in general, throw OOB error.

        # TODO: If no end was given, then it defaults to that large int.
        # Accidentally including the 0 (null) characters will mess up strings due to null termination. __str__ expects the exact length of the string from self.write_position.
        var end = limits.end
        if limits.end == 2147483647:
            end = self.size()
        elif limits.end > self.size() + 1:
            panic(
                "builtins.Bytes.__getitem__: Index out of range for limits.end."
                " Received: "
                + str(limits.end)
                + " but the length is "
                + str((self.size()))
            )

        var new_bytes = Self(size=self.capacity())
        for i in range(limits.start, end, limits.step):
            new_bytes.append(self._vector[i])

        return new_bytes

    fn __setitem__(inout self, index: Int, value: Int8):
        if index >= len(self._vector):
            panic(
                "Bytes.__setitem__: Tried setting index out of range. Vector length is "
                + str(len(self._vector))
                + " but tried to set index "
                + str(index)
                + "."
            )

        self._vector[index] = value
        if index >= self.write_position:
            self.write_position = index + 1

    fn __setitem__(inout self, index: Int, value: Self):
        if index >= len(self._vector):
            panic(
                "Bytes.__setitem__: Tried setting index out of range. Vector length is "
                + str(len(self._vector))
                + " but tried to set index "
                + str(index)
                + "."
            )

        self._vector[index] = value[0]
        if index >= self.write_position:
            self.write_position = index + 1

    fn __eq__(self, other: Self) -> Bool:
        if len(self) != len(other):
            return False
        for i in range(len(self)):
            if self[i] != other[i]:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __add__(self, other: Self) -> Self:
        var new_vector = List[Int8](capacity=len(self) + len(other))
        for i in range(len(self)):
            new_vector.append(self[i])
        for i in range(len(other)):
            new_vector.append(other[i])
        return Bytes(new_vector)

    fn __iadd__(inout self: Self, other: Self):
        # Up the capacity if the the length of the internal vectors exceeds the current capacity. We are not checking the numbers of bytes written to the Bytes structs.
        var length_of_self = len(self)
        var length_of_other = len(other)

        var added_size = length_of_self + length_of_other
        if self.size() < added_size:
            self.resize(added_size * 2)

        # Copy over data starting from the write position.
        for i in range(len(other)):
            self._vector[self.write_position] = other[i]
            self.write_position += 1

    fn __str__(self) -> String:
        # Don't need to add a null terminator becasue we know the exact length of the string.
        # It seems like this works even with unicode characters because len() does return 1-4 depending on the character.
        # If Bytes has funky output for this function, go back to copying the internal vector and null terminating it.
        return StringRef(self._vector.data.value, self.write_position)

    fn __repr__(self) -> String:
        return self.__str__()

    fn __contains__(self, item: Int8) -> Bool:
        for i in range(len(self)):
            if self[i] == item:
                return True
        return False

    fn append(inout self, value: Byte):
        """Appends the value to the end of the Bytes.

        Args:
            value: The value to append.
        """
        # If the vector is full, resize it.
        if self.write_position >= self.size():
            self.resize(self.size() * 2)
        self[self.write_position] = value

    fn extend(inout self, value: String):
        """Appends the values to the end of the Bytes.

        Args:
            value: The value to append.
        """
        self += value

    fn extend(inout self, value: List[Int8]):
        """Appends the values to the end of the Bytes.

        Args:
            value: The value to append.
        """
        self += value

    fn index_byte(self, c: Byte) -> Int:
        """Return the index of the first occurrence of the byte c.

        Args:
            c: The byte to search for.

        Returns:
            The index of the first occurrence of the byte c.
        """
        var i = 0
        for i in range(len(self)):
            if self[i] == c:
                return i

        return -1

    fn has_prefix(self, prefix: Self) raises -> Bool:
        """Reports whether the Bytes struct begins with prefix.

        Args:
            prefix: The prefix to search for.

        Returns:
            True if the Bytes struct begins with prefix; otherwise, False.
        """
        var len_comparison = len(self) >= len(prefix)
        var prefix_comparison = self[0 : len(prefix)] == prefix
        return len_comparison and prefix_comparison

    fn has_suffix(self, suffix: Self) raises -> Bool:
        """Reports whether the Bytes struct ends with suffix.

        Args:
            suffix: The prefix to search for.

        Returns:
            True if the Bytes struct ends with suffix; otherwise, False.
        """
        var len_comparison = len(self) >= len(suffix)
        var suffix_comparison = self[len(self) - len(suffix) : len(self)] == suffix
        return len_comparison and suffix_comparison

    fn capacity(self) -> Int:
        """Returns the capacity of the Bytes struct."""
        return self._vector.capacity

    fn copy(self) -> Self:
        """Returns a copy of the Bytes struct. Only copies up to what has been written to the Bytes struct.
        """
        # Copy elements up to the write position, don't need to copy over empty elements from end of the vector.
        var bytes_copy = Self(size=self.write_position)
        for i in range(self.write_position):
            bytes_copy.append(self._vector[i])
        return bytes_copy

    fn get_bytes(self) -> List[Int8]:
        """
        Returns a copy of the byte array of the string builder.

        Returns:
          The byte array of the string builder.
        """
        return self.copy()._vector

    fn get_null_terminated_bytes(self) -> List[Int8]:
        """
        Returns a copy of the byte array of the string builder with a null terminator.

        Returns:
          The byte array of the string builder with a null terminator.
        """
        var new_bytes = self.copy()._vector
        new_bytes.append(0)
        return new_bytes
