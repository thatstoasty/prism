from sys import exit, stderr

from prism import Command, Flag, FlagSet, Version, no_args


fn base(args: List[String], flags: FlagSet) -> None:
    print("Pass a subcommand!")


fn connect(args: List[String], flags: FlagSet) raises -> None:
    if host := flags.get_string("host"):
        print("Connecting to", host.value())
    else:
        raise Error("Error: Exit Code 2")


fn my_exit(e: Error) -> None:
    print(e, file=stderr)
    if e.as_string_slice() == "Error: Exit Code 2":
        print("Exiting with code 2")
        exit(2)
    else:
        exit(1)


fn allow_hosts(args: List[String], flags: FlagSet) raises -> None:
    var hosts = flags.get_string_list("hosts")
    if not hosts:
        print("Received no names to print.")
        return

    print("Allowing: ", hosts.value().__str__())


fn version(version: String) -> String:
    return "MyCLI version: " + version


fn validate_hosts(value: String) raises -> None:
    alias approved_hosts = List[String]("localhost", "0.0.0.0", "192.168.1.1")
    var hosts = value.split(" ")
    for host in hosts:
        if String(host) not in approved_hosts:
            raise Error(
                "ValueError: Host provided is not permitted.\nReceived: ",
                host,
                " Approved: ",
                approved_hosts.__str__(),
            )


fn main() -> None:
    var cli = Command(
        name="connector",
        usage="Base Command.",
        run=base,
        exit=my_exit,
        version=Version("0.1.0", action=version),
        suggest=True,
        flags=[
            Flag.bool(name="required", shorthand="r0", usage="Always required.", required=True, persistent=True),
            Flag.string(
                name="host",
                shorthand="h",
                usage="Host",
                persistent=True,
                environment_variable=String("CONNECTOR_HOST"),
                file_path=String("~/.myapp/config"),
                default=String("localhost"),
            ),
            Flag.string(
                name="port",
                shorthand="p",
                usage="Port",
                persistent=True,
            ),
            Flag.bool(
                name="automation",
                shorthand="a",
                usage="In automation?",
                persistent=True,
            ),
            Flag.bool(
                name="verbose",
                shorthand="vv",
                usage="Verbose output.",
                persistent=True,
            ),
        ],
        flags_required_together=["host", "port"],
        children=[
            Command(
                name="connect",
                usage="Connect to a database.",
                raising_run=connect,
                aliases=["db-connect"],
                flags=[
                    Flag.bool(
                        name="also",
                        shorthand="a",
                        usage="Also always required.",
                        required=True,
                    ),
                    Flag.string(
                        name="uri",
                        shorthand="u",
                        usage="URI",
                    ),
                ],
                arg_validator=no_args,
                suggest=True,
            ),
            Command(
                name="allow",
                usage="Add hosts to the allow list!",
                raising_run=allow_hosts,
                flags=[
                    Flag.string_list(
                        name="hosts",
                        shorthand="hl",
                        usage="Hosts to add to the allowlist.",
                        default=List[String]("localhost", "0.0.0.0"),
                        action=validate_hosts,
                    )
                ],
                read_from_stdin=True,
            ),
        ],
    )
    cli.execute()
