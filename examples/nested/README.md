# Nested

![Nested Example](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/images/nested.png)

Start by navigating to the `nested` example directory.
`cd examples/nested`

Run the example by using the following command, we're not specifying a subcommand so we should be executing the root command.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested/nested-1.gif)

Now try running it with a subcommand.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested/nested-2.gif)

Let's follow the suggestion and add the cat subcommand.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested/nested-3.gif)

Now try running it with a flag to get three facts.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested/nested-4.gif)

Let's try running it from a compiled binary instead. Start by setting your `MOJO_PYTHON_LIBRARY` environment variable to your default python3 installation. We need to do this because we're using the `requests` module via Python interop.
`export MOJO_PYTHON_LIBRARY=$(which python3)`

Compile the example file into a binary.
`mojo build nested.mojo`

Now run the previous command, but with the binary instead.
`./nested --count 3`

You should get the same result as before! But, what about command information?

```bash
./nested get cat --help
Get some cat facts!

Usage:
  nested get cat [args] [flags]

Available commands:

Available flags:
  -h, --help    Displays help information about the command.
  -c, --count    Number of facts to get.

Use "root get cat [command] --help" for more information about a command.
```

Usage information will be printed the console by passing the `--help` flag.
