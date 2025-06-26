from prism._flag_set import Annotation


alias FlagActionFn = fn (String) raises -> None
"""The type of a function that runs after a flag has been processed."""


@fieldwise_init
struct FType(Copyable, EqualityComparable, ExplicitlyCopyable, Movable):
    """Flag types enum helper."""

    var value: String
    """The value of the flag type."""
    alias String = Self("String")
    alias Bool = Self("Bool")
    alias Int = Self("Int")
    alias Int8 = Self("Int8")
    alias Int16 = Self("Int16")
    alias Int32 = Self("Int32")
    alias Int64 = Self("Int64")
    alias UInt = Self("UInt")
    alias UInt8 = Self("UInt8")
    alias UInt16 = Self("UInt16")
    alias UInt32 = Self("UInt32")
    alias UInt64 = Self("UInt64")
    alias Float16 = Self("Float16")
    alias Float32 = Self("Float32")
    alias Float64 = Self("Float64")
    alias StringList = Self("StringList")
    alias IntList = Self("IntList")
    alias Float64List = Self("Float64List")

    fn is_int_type(self) -> Bool:
        """Returns if the type is an integer type.

        Returns:
            True if the type is an integer type, False otherwise.
        """
        alias int_types = InlineArray[String, 10](
            "Int",
            "Int8",
            "Int16",
            "Int32",
            "Int64",
            "UInt",
            "UInt8",
            "UInt16",
            "UInt32",
            "UInt64",
        )
        return self.value in int_types

    fn is_float_type(self) -> Bool:
        """Returns if the type is an float type.

        Returns:
            True if the type is an float type, False otherwise.
        """
        alias float_types = InlineArray[String, 3]("Float16", "Float32", "Float64")
        return self.value in float_types

    fn is_list_type(self) -> Bool:
        """Returns if the type is a list type.

        Returns:
            True if the type is a list type, False otherwise.
        """
        alias list_types = InlineArray[String, 3]("StringList", "IntList", "Float64List")
        return self.value in list_types

    fn is_valid(self) -> Bool:
        """Returns if the type is a valid type.

        Returns:
            True if the type is a valid type, False otherwise.
        """
        alias valid_types = InlineArray[String, 18](
            "String",
            "Bool",
            "Int",
            "Int8",
            "Int16",
            "Int32",
            "Int64",
            "UInt",
            "UInt8",
            "UInt16",
            "UInt32",
            "UInt64",
            "Float16",
            "Float32",
            "Float64",
            "StringList",
            "IntList",
            "Float64List",
        )

        return self.value in valid_types

    fn __eq__(self, other: Self) -> Bool:
        """Compares two FType objects for equality.

        Args:
            other: The other FType to compare against.

        Returns:
            True if the FTypes are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Compares two FType objects for inequality.

        Args:
            other: The other FType to compare against.

        Returns:
            True if the FTypes are not equal, False otherwise.
        """
        return self.value != other.value


# TODO: When we have trait objects, switch to using actual flag structs per type instead of
# needing to cast values to and from string.
@fieldwise_init
struct Flag(Copyable, ExplicitlyCopyable, Movable, Representable, Stringable, Writable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via `--name` or `-shorthand` and can have a value associated with them.
    """

    var name: String
    """The full name of the flag."""
    var shorthand: String
    """The shorthand of the flag."""
    var usage: String
    """The usage of the flag."""
    var value: Optional[String]
    """The value of the flag."""
    var environment_variable: Optional[String]
    """If no value is provided, will optionally check this environment variable for a value."""
    var file_path: Optional[String]
    """If no value is provided, will optionally check read this file for a value. `environment_variable` takes precedence over this option."""
    var default: Optional[String]
    """The default value of the flag."""
    var type: FType
    """The type of the flag."""
    var annotations: Dict[String, List[String]]
    """The annotations of the flag which are used to determine grouping."""
    var action: Optional[FlagActionFn]
    """Function to run after the flag has been processed."""
    var changed: Bool
    """If the flag has been changed from its default value."""
    var required: Bool
    """If the flag is required."""
    var persistent: Bool
    """If the flag should persist to children commands."""

    fn __init__(
        out self,
        name: String,
        type: FType,
        *,
        shorthand: String = "",
        usage: String = "",
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        default: Optional[String] = None,
        required: Bool = False,
        persistent: Bool = False,
    ):
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            type: The type of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            default: The default value of the flag.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage
        self.value = None
        self.environment_variable = environment_variable
        self.file_path = file_path
        self.default = default
        self.type = type
        self.annotations = Dict[String, List[String]]()
        self.action = action
        self.changed = False
        self.required = required
        self.persistent = persistent

    fn __str__(self) -> String:
        """Returns a string representation of the Flag.

        Returns:
            The string representation of the Flag.
        """
        return String.write(self)

    fn __repr__(self) -> String:
        """Returns a string representation of the Flag.

        Returns:
            The string representation of the Flag.
        """
        return self.__str__()

    fn __eq__(self, other: Self) -> Bool:
        """Compares two Flags for equality.

        Args:
            other: The other Flag to compare against.

        Returns:
            True if the Flags are equal, False otherwise.
        """
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
        """Compares two Flags for inequality.

        Args:
            other: The other Flag to compare against.

        Returns:
            True if the Flags are not equal, False otherwise.
        """
        return not self == other

    fn write_to[W: Writer, //](self, mut writer: W):
        """Write Flag string representation to a writer.

        Parameters:
            W: The type of writer to write to.

        Args:
            writer: The formatter to write to.
        """

        @parameter
        fn write_optional(opt: Optional[String]):
            if opt:
                writer.write(repr(opt.value()))
            else:
                writer.write(repr(None))

        writer.write("Flag(name=", self.name)
        if self.shorthand != "":
            writer.write(", shorthand=", self.shorthand)
        writer.write(", Usage=", self.usage)
        if self.value:
            writer.write(", value=")
            write_optional(self.value)
        if self.default:
            writer.write(", default=")
            write_optional(self.default)
        writer.write(
            ", type=",
            self.type.value,
            ", changed=",
            self.changed,
            ", required=",
            self.required,
            ", persistent=",
            self.persistent,
            ")",
        )

    fn set(mut self, value: StringSlice) -> None:
        """Sets the value of the flag.

        Args:
            value: The value to set.
        """
        self.value = String(value)
        self.changed = True

    fn get_with_transform[T: Movable & Copyable, //, transform: fn (value: StringSlice) -> T](self) -> Optional[T]:
        """Returns the value of the flag with a transformation applied to it.

        Parameters:
            T: The type of the value to return.
            transform: The transformation to apply to the value.

        Returns:
            The transformed value of the flag.
        """
        if self.value:
            return transform(self.value.value())
        elif self.default:
            return transform(self.default.value())

        return None

    fn value_or_default(self) -> Optional[String]:
        """Returns the value of the flag or the default value if it isn't set.

        Returns:
            The value of the flag or the default value.
        """
        if self.value:
            return self.value.value()
        elif self.default:
            return self.default.value()

        return None

    fn names(self) -> List[String]:
        """Returns the names of the flag.

        Returns:
            The names of the flag.
        """
        var names = List[String](self.name, self.shorthand)
        # TODO: Add aliases to list when flags support them.
        return names^

    @staticmethod
    fn string(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[String] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `String` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.String,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn bool(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Bool] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `Bool` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Bool,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn int(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Int] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Adds an `Int` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Int,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn int8(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Int8] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Adds an `Int8` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Int8,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn int16(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Int16] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Adds an `Int16` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Int16,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn int32(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Int32] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Adds an `Int32` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Int32,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn int64(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Int64] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Adds an `Int64` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Int64,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn uint(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[UInt] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `UInt` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.UInt,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn uint8(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[UInt8] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `UInt8` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.UInt8,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn uint16(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[UInt16] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `UInt16` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.UInt16,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn uint32(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[UInt32] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `UInt32` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.UInt32,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn uint64(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[UInt64] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `UInt64` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.UInt64,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn float16(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Float16] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `Float16` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Float16,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn float32(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Float32] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `Float32` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Float32,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn float64(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[Float64] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `Float64` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = String(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Float64,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn string_list(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[List[String]] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `StringList` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = StaticString(" ").join(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.StringList,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn int_list(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[List[Int, True]] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `IntList` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = StaticString(" ").join(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.IntList,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )

    @staticmethod
    fn float64_list(
        name: StringSlice,
        usage: StringSlice,
        shorthand: String = "",
        default: Optional[List[Float64, True]] = None,
        environment_variable: Optional[String] = None,
        file_path: Optional[String] = None,
        action: Optional[FlagActionFn] = None,
        required: Bool = False,
        persistent: Bool = False,
    ) -> Flag:
        """Constructs a `Float64List` flag.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
            environment_variable: The environment variable to check for a value.
            file_path: The file to check for a value.
            action: Function to run after the flag has been processed.
            required: If the flag is required.
            persistent: If the flag should persist to children commands.

        Returns:
            Flag: The flag object.
        """
        var default_value: Optional[String]
        if default:
            default_value = StaticString(" ").join(default.value())
        else:
            default_value = None

        return Flag(
            name=String(name),
            shorthand=shorthand,
            usage=String(usage),
            default=default_value,
            type=FType.Float64List,
            environment_variable=environment_variable,
            file_path=file_path,
            action=action,
            required=required,
            persistent=persistent,
        )
