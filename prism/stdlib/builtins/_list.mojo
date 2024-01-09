from collections.vector import DynamicVector


struct ListIter[T: CollectionElement]:
    var data: list[T]
    var idx: Int

    fn __init__(inout self, data: list[T]):
        self.idx = -1
        self.data = data

    fn __len__(self) -> Int:
        return len(self.data) - self.idx - 1

    fn __next__(inout self) raises -> T:
        self.idx += 1
        return self.data[self.idx]


@value
struct list[T: CollectionElement](Sized, Movable):
    var _internal_vector: DynamicVector[T]

    fn __init__(inout self):
        self._internal_vector = DynamicVector[T]()

    fn __init__(inout self, owned value: DynamicVector[T]):
        self._internal_vector = value

    @always_inline
    fn _normalize_index(self, index: Int) -> Int:
        if index < 0:
            return len(self) + index
        else:
            return index

    fn append(inout self, value: T):
        self._internal_vector.push_back(value)

    fn clear(inout self):
        self._internal_vector.clear()

    fn copy(self) -> list[T]:
        return list(self._internal_vector)

    fn extend(inout self, other: list[T]):
        for i in range(len(other)):
            self.append(other.unchecked_get(i))

    fn pop(inout self, index: Int = -1) raises -> T:
        if index >= len(self._internal_vector):
            raise Error("list index out of range")
        let new_index = self._normalize_index(index)
        let element = self.unchecked_get(new_index)
        for i in range(new_index, len(self) - 1):
            self[i] = self[i + 1]
        self._internal_vector.resize(len(self._internal_vector) - 1, element)
        return element

    fn reverse(inout self) raises:
        for i in range(len(self) // 2):
            let mirror_i = len(self) - 1 - i
            let tmp = self[i]
            self[i] = self[mirror_i]
            self[mirror_i] = tmp

    fn insert(inout self, key: Int, value: T) raises:
        let index = self._normalize_index(key)
        if index >= len(self):
            self.append(value)
            return
        # we increase the size of the array before insertion
        self.append(self[-1])
        for i in range(len(self) - 2, index, -1):
            self[i] = self[i - 1]
        self[key] = value

    fn __getitem__(self, index: Int) raises -> T:
        if index >= len(self._internal_vector):
            raise Error("list index out of range")
        return self.unchecked_get(self._normalize_index(index))

    fn __getitem__(self: Self, limits: slice) raises -> Self:
        var new_list: Self = Self()
        for i in range(limits.start, limits.end, limits.step):
            new_list.append(self[i])
        return new_list

    @always_inline
    fn unchecked_get(self, index: Int) -> T:
        return self._internal_vector[index]

    fn __setitem__(inout self, key: Int, value: T) raises:
        if key >= len(self._internal_vector):
            raise Error("list index out of range")
        self.unchecked_set(self._normalize_index(key), value)

    @always_inline
    fn unchecked_set(inout self, key: Int, value: T):
        self._internal_vector[key] = value

    @always_inline
    fn __len__(self) -> Int:
        return len(self._internal_vector)

    fn __iter__(self: Self) -> ListIter[T]:
        return ListIter(self)

    @staticmethod
    fn from_string(input_value: String) -> list[String]:
        var result = list[String]()
        for i in range(len(input_value)):
            result.append(input_value[i])
        return result


fn list_to_str(input_list: list[String]) raises -> String:
    var result: String = "["
    for i in range(len(input_list)):
        let repr = "'" + str(input_list[i]) + "'"
        if i != len(input_list) - 1:
            result += repr + ", "
        else:
            result += repr
    return result + "]"


fn list_to_str(input_list: list[Int]) raises -> String:
    var result: String = "["
    for i in range(len(input_list)):
        let repr = str(input_list.__getitem__(index=i))
        if i != len(input_list) - 1:
            result += repr + ", "
        else:
            result += repr
    return result + "]"
