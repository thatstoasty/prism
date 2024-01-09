@value
struct Optional[T: CollectionElement](CollectionElement):
    var has_value: Bool
    var values: list[T]

    fn __init__(inout self, value: T):
        self.has_value = True
        self.values = list[T]()
        self.values.append(value)

    fn __init__(inout self, value: None):
        self.has_value = False
        self.values = list[T]()

    fn __is__(self, other: None) -> Bool:
        return not self.has_value

    fn value(self) -> T:
        return self.values.unchecked_get(0)
