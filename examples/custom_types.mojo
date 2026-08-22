from prism import Arg, ArgSet, Command, Flag, FlagSet, FromValue, ToValue, read_args


@fieldwise_init
struct Duration(FromValue, ToValue, ImplicitlyCopyable, Movable, Writable):
    """A span of time, written like `30s`, `5m` or `2h`."""

    var seconds: Int

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Parses `30s`, `5m` or `2h` into a number of seconds."""
        if value.byte_length() < 2:
            raise Error(t"Expected a duration like `30s`, `5m` or `2h`. Received: `{value}`")

        var unit = value[byte = value.byte_length() - 1 :]
        var amount = atol(value[byte = 0 : value.byte_length() - 1])

        if unit == "s":
            return Self(amount)
        elif unit == "m":
            return Self(amount * 60)
        elif unit == "h":
            return Self(amount * 3600)

        raise Error(t"Unknown duration unit `{unit}`. Expected one of: s, m, h.")

    def to_value(self) -> String:
        """Renders the duration back to the text form `from_value` accepts."""
        return String(self.seconds, "s")

    def write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the duration for display."""
        writer.write(self.seconds, "s")


@fieldwise_init
struct Endpoint(FromValue, ToValue, ImplicitlyCopyable, Movable, Writable):
    """A network address, written like `localhost:8080`."""

    var host: String
    var port: UInt16

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        """Parses `host:port`, rejecting a port outside the valid range."""
        var separator = value.find(":")
        if separator == -1:
            raise Error(t"Expected an address like `localhost:8080`. Received: `{value}`")

        var port = atol(value[byte = separator + 1 :])
        if port < 1 or port > 65535:
            raise Error(t"Port out of range: {port}. Expected 1 to 65535.")

        return Self(String(value[byte=0:separator]), UInt16(port))

    def to_value(self) -> String:
        """Renders the endpoint back to the text form `from_value` accepts."""
        return String(self.host, ":", self.port)

    def write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the endpoint for display."""
        writer.write(self.host, ":", self.port)


def serve(args: ArgSet, flags: FlagSet) raises -> None:
    """Reads a custom type out of both an argument and a flag."""
    var endpoint = args.get[Endpoint]("endpoint").value()
    var timeout = flags.get[Duration]("timeout").value()

    print("Serving on host:", endpoint.host, "port:", endpoint.port)
    print(t"Timeout: {timeout} ({timeout.seconds} seconds)")


def main() -> None:
    var cli = Command(
        name="custom-types",
        usage="Uses types of its own for a flag and an argument.",
        run=serve,
        args=[
            # A custom type works anywhere a built-in one does.
            Arg.new[Endpoint](name="endpoint", usage="Address to bind, as host:port."),
        ],
        flags=[
            # The default is stored by calling `to_value`, and read back with `from_value`, so the
            # two have to be inverses of each other.
            Flag.new[Duration](
                name="timeout",
                shorthand="t",
                usage="How long to wait for a request.",
                default=Optional[Duration](Duration(30)),
            ),
        ],
    )
    cli.execute(read_args())
