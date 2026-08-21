from prism import Arg, ArgSet, Command, Flag, FlagSet, read_args


def deploy(args: ArgSet, flags: FlagSet) raises -> None:
    """Reads declared arguments by name and type, rather than by index."""
    var env = args.get[String]("environment").value()
    var replicas = args.get[Int]("replicas").value()
    var ratio = args.get[Float64]("ratio").value()

    print("Deploying to", env)
    print("  replicas:", replicas)
    print("  traffic ratio:", ratio)

    if flags.get_bool("dry-run").or_else(False):
        print("  (dry run, nothing was changed)")


def logs(args: ArgSet, flags: FlagSet) raises -> None:
    """Declaring arguments does not take the raw positional values away."""
    print("Service:", args.get[String]("service").value())
    print("  same value, read positionally:", args[0], "| count:", len(args))


def echo(args: ArgSet, flags: FlagSet) -> None:
    """A command that declares no arguments still accepts any number of them."""
    for arg in args:
        print("echo:", arg)


def main() -> None:
    var cli = Command(
        name="named-args",
        usage="Demonstrates named, typed positional arguments.",
        run=echo,
        # A parent command rejects unrecognized positional arguments by default, on the assumption
        # that they are mistyped subcommand names. This root takes arguments of its own, so it opts
        # out and passes them to `echo` instead.
        reject_unknown_subcommands=False,
        children=[
            Command(
                name="deploy",
                usage="Deploy a service to an environment.",
                run=deploy,
                args=[
                    # Required, and constrained to a fixed set of values.
                    Arg.string(
                        name="environment",
                        usage="Where to deploy to.",
                        valid_values=["staging", "production"],
                    ),
                    # Required, and parsed as an Int before `run` is called.
                    Arg.int(name="replicas", usage="How many replicas to run."),
                    # Optional: giving a default makes it so.
                    Arg.float64(name="ratio", usage="Fraction of traffic to send.", default=1.0),
                ],
                flags=[
                    Flag.bool(name="dry-run", shorthand="d", usage="Print the plan and stop.")
                ],
            ),
            Command(
                name="logs",
                usage="Show logs for a service.",
                run=logs,
                args=[Arg.string(name="service", usage="The service to read logs for.")],
            ),
        ],
    )
    cli.execute(read_args())
