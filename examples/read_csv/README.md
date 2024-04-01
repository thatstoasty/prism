# Stump Logger Example

This example is a toy example that demonstrates using Maxim's `mojo-csv` parser and the `gojo` `CSVReader` which wraps it within a `Prism` CLI.
The example is set up to read the file and print the first element of N lines.

Let's try reading a file.

```bash
mojo run examples/read_csv/root.mojo --file=examples/read_csv/file.csv

Mojo
Mojo
Mojo
```

Let's try reading a file with a specific line count.

```bash
mojo run examples/read_csv/root.mojo --file=examples/read_csv/file.csv --lines=1

Mojo
```

What if we try a file that doesn't exist?

```bash
mojo run examples/read_csv/root.mojo --file=foobar.csv

Unhandled exception caught during execution: File does not exist.
mojo: error: execution exited with a non-zero result: 1
```

We set a restriction of no args being passed to the CLI. Running with any args should fail.

```bash
mojo run examples/read_csv/root.mojo --file=examples/read_csv/file.csv foobar

Unhandled exception caught during execution: Command does not take any arguments
mojo: error: execution exited with a non-zero result: 1
```
