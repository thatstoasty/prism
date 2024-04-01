# Stump Logger Example

This example is a toy example that demonstrates using the `Stump` logger in a `Prism` CLI.

Defaults to JSON formatting

```bash
mojo run examples/logging/root.mojo hello

{"message":"hello","timestamp":"2024-04-01 15:10:40","level":"INFO"}
```

JSON can be explicitly specified as well.

```bash
mojo run examples/logging/root.mojo --type=json hello

{"message":"hello","timestamp":"2024-04-01 15:10:40","level":"INFO"}
```

The custom formatted logger can be used as well.

```bash
mojo run examples/logging/root.mojo --type=custom hello

2024 INFO hello name=Name
```

We set a minimum of one arg to be passed to the CLI. Running with no args should fail.

```bash
mojo run examples/logging/root.mojo

Unhandled exception caught during execution: Command accepts at least 1 arguments. Received: 0.
mojo: error: execution exited with a non-zero result: 1
```
