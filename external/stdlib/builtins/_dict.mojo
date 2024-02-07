"""This is an implementation of dict taken from the 
awesome https://github.com/mzaks/mojo-hash"""

from memory import memset_zero, memcpy
from ._hash import hash, HashableCollectionElement
from ._generic_list import list

alias EMPTY_BUCKET = -1


@value
struct CustomBool(CollectionElement):
    var value: Bool

    fn __init__(inout self, value: Bool):
        self.value = value

    fn __bool__(self) -> Bool:
        return self.value


@value
struct HashableInt(HashableCollectionElement, Intable):
    var value: Int

    fn __init__(inout self, value: Int):
        self.value = value

    fn __hash__(self) -> Int:
        return hash(self.value)

    fn __eq__(self, other: HashableInt) -> Bool:
        return self.value == other.value

    fn __int__(self) -> Int:
        return self.value


@value
struct HashableStr(HashableCollectionElement, Stringable):
    var value: String

    fn __init__(inout self, value: StringLiteral):
        self.value = value

    fn __init__(inout self, value: String):
        self.value = value

    fn __hash__(self) -> Int:
        return hash(self.value)

    fn __eq__(self, other: HashableStr) -> Bool:
        return self.value == other.value

    fn __str__(self) -> String:
        return self.value


@value
struct dict[K: HashableCollectionElement, V: CollectionElement](Sized):
    var _keys: list[K]
    var _values: list[V]
    var _key_map: list[Int]
    var _deleted_mask: list[CustomBool]
    var _count: Int
    var _capacity: Int

    fn __init__(inout self):
        self._count = 0
        self._capacity = 16
        self._keys = list[K]()
        self._values = list[V]()
        self._key_map = list[Int]()
        self._deleted_mask = list[CustomBool]()
        self._initialize_key_map(self._capacity)

    fn __setitem__(inout self, key: K, value: V):
        if self._count / self._capacity >= 0.8:
            self._rehash()

        self._put(key, value, -1)

    fn _initialize_key_map(inout self, size: Int):
        self._key_map.clear()
        for i in range(size):
            self._key_map.append(EMPTY_BUCKET)  # -1 means unused

    fn _rehash(inout self):
        let old_mask_capacity = self._capacity
        self._capacity *= 2
        self._initialize_key_map(self._capacity)

        for i in range(len(self._keys)):
            self._put(self._keys.unchecked_get(i), self._values.unchecked_get(i), i)

    fn _put(inout self, key: K, value: V, rehash_index: Int):
        let key_hash = hash(key)
        let modulo_mask = self._capacity
        var key_map_index = key_hash % modulo_mask
        while True:
            let key_index = self._key_map.unchecked_get(index=key_map_index)
            if key_index == EMPTY_BUCKET:
                let new_key_index: Int
                if rehash_index == -1:
                    self._keys.append(key)
                    self._values.append(value)
                    self._deleted_mask.append(False)
                    self._count += 1
                    new_key_index = len(self._keys) - 1
                else:
                    new_key_index = rehash_index
                self._key_map.unchecked_set(key_map_index, new_key_index)
                return

            let existing_key = self._keys.unchecked_get(key_index)
            if existing_key == key:
                self._values.unchecked_set(key_index, value)
                if self._deleted_mask.unchecked_get(key_index).value:
                    self._count += 1
                    self._deleted_mask.unchecked_set(key_index, False)
                return

            key_map_index = (key_map_index + 1) % modulo_mask

    fn __getitem__(self, key: K) raises -> V:
        let key_hash = hash(key)
        let modulo_mask = self._capacity
        var key_map_index = key_hash % modulo_mask
        while True:
            let key_index = self._key_map.__getitem__(index=key_map_index)
            if key_index == EMPTY_BUCKET:
                raise Error("Key not found")
            let other_key = self._keys.unchecked_get(key_index)
            if other_key == key:
                if self._deleted_mask[key_index]:
                    raise Error("Key not found")
                return self._values[key_index]
            key_map_index = (key_map_index + 1) % modulo_mask

    fn get(self, key: K, default: V) -> V:
        try:
            return self[key]
        except Error:
            return default

    fn pop(inout self, key: K) raises:
        let key_hash = hash(key)
        let modulo_mask = self._capacity
        var key_map_index = key_hash % modulo_mask
        while True:
            let key_index = self._key_map.__getitem__(index=key_map_index)
            if key_index == EMPTY_BUCKET:
                raise Error("KeyError, key not found.")
            let other_key = self._keys.unchecked_get(key_index)
            if other_key == key:
                self._count -= 1
                self._deleted_mask[key_index] = True
                return
            key_map_index = (key_map_index + 1) % modulo_mask

    fn __len__(self) -> Int:
        return self._count

    fn items(self) -> KeyValueIterator[K, V]:
        return KeyValueIterator(self)


@value
struct Pair[K: HashableCollectionElement, V: CollectionElement]:
    var key: K
    var value: V


@value
struct KeyValueIterator[K: HashableCollectionElement, V: CollectionElement]:
    var _dict: dict[K, V]
    var idx: Int
    var elements_seen: Int

    fn __init__(inout self, dict_: dict[K, V]):
        self.idx = -1
        self.elements_seen = 0
        self._dict = dict_

    fn __len__(self) -> Int:
        return len(self._dict) - self.elements_seen

    fn __next__(inout self) -> Pair[K, V]:
        self.idx += 1
        while self.idx < len(self._dict._deleted_mask):
            if self._dict._deleted_mask.unchecked_get(self.idx):
                self.idx += 1
                continue
            self.elements_seen += 1
            break
        return Pair(
            self._dict._keys.unchecked_get(self.idx),
            self._dict._values.unchecked_get(self.idx),
        )

    fn __iter__(self) -> KeyValueIterator[K, V]:
        return self
