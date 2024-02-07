from sys.info import sizeof


trait Equalable:
    fn __eq__(self: Self, other: Self) -> Bool:
        ...


trait Hashable(Equalable):
    fn __hash__(self) -> Int:
        ...


fn hash[T: Hashable](x: T) -> Int:
    return x.__hash__()


fn hash(x: Int) -> Int:
    return x


fn hash(x: Int64) -> Int:
    """We assume 64 bits here, which is a big assumption.
    TODO: Make it work for 32 bits.
    """
    return hash(x.to_int())


fn hash(x: String) -> Int:
    """Very simple hash function."""
    let prime = 31
    var hash_value = 0
    for i in range(len(x)):
        hash_value = prime * hash_value + ord(x[i])
    return hash_value


trait HashableCollectionElement(CollectionElement, Hashable):
    pass
