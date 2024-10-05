from collections import Optional, Dict


# Individual flag annotations
alias REQUIRED = "REQUIRED"

# Flag Group annotations
alias REQUIRED_AS_GROUP = "REQUIRED_AS_GROUP"
alias ONE_REQUIRED = "ONE_REQUIRED"
alias MUTUALLY_EXCLUSIVE = "MUTUALLY_EXCLUSIVE"


@value
struct Flag(RepresentableCollectionElement, Stringable, Formattable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via --name or -shorthand and can have a value associated with them.
    """

    var name: String
    """The full name of the flag."""
    var shorthand: String
    """The shorthand of the flag."""
    var usage: String
    """The usage of the flag."""
    var value: Optional[String]
    """The value of the flag."""
    var default: String
    """The default value of the flag."""
    var type: String
    """The type of the flag."""
    var annotations: Dict[String, List[String]]
    """The annotations of the flag which are used to determine grouping."""
    var changed: Bool
    """Whether the flag has been changed from its default value."""

    fn __init__(
        inout self,
        name: String,
        type: String,
        shorthand: String = "",
        usage: String = "",
        value: Optional[String] = None,
        default: String = "",
    ) -> None:
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            type: The type of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage
        self.value = value
        self.default = default
        self.type = type
        self.annotations = Dict[String, List[String]]()
        self.changed = False

    fn __str__(self) -> String:
        var output = String()
        var writer = output._unsafe_to_formatter()
        self.format_to(writer)
        return output

    fn __repr__(self) -> String:
        return self.__str__()

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.name == other.name
            and self.shorthand == other.shorthand
            and self.usage == other.usage
            and self.value == other.value
            and self.default == other.default
            and self.type == other.type
            and self.changed == other.changed
        )

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn format_to(self, inout writer: Formatter):
        """Write Flag string representation to a `Formatter`.

        Args:
            writer: The formatter to write to.
        """

        @parameter
        fn write_optional(opt: Optional[String]):
            if opt:
                writer.write(repr(opt.value()))
            else:
                writer.write(repr(None))

        writer.write("Flag(Name: ")
        writer.write(self.name)

        if self.shorthand != "":
            writer.write(", Shorthand: ")
            writer.write(self.shorthand)
        writer.write(", Usage: ")
        writer.write(self.usage)

        if self.value:
            writer.write(", Value: ")
            write_optional(self.value)
        writer.write(", Default: ")
        writer.write(self.default)
        writer.write(", Type: ")
        writer.write(self.type)
        writer.write(", Changed: ")
        writer.write(self.changed)
        writer.write(")")

    fn set(inout self, value: String) -> None:
        """Sets the value of the flag.

        Args:
            value: The value to set.
        """
        self.value = value
        self.changed = True

    fn get_with_transform[T: CollectionElement, //, transform: fn (value: String) -> T](self) -> Optional[T]:
        """Returns the value of the flag with a transformation applied to it.

        Params:
            transform: The transformation to apply to the value.

        Returns:
            The transformed value of the flag.
        """
        if self.value:
            return transform(self.value.value())
        return transform(self.default)
