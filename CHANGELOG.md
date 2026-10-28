# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the major version is 0, breaking changes bump the
minor version.

## [0.5.0] - Unreleased

Requires Mojo 1.2.0.

### Breaking

- Require Mojo `=1.2.0` and mog `v0.4.0`.
- Remove `Flag.file_path`. A flag's fallback is now its environment variable only, and value precedence is command
  line, then environment variable, then default. `Flag.from_fallback` is renamed `Flag.from_environment`.
- `FromValue.from_value` takes an `ImmStringSpan` instead of a `StringSpan`. Custom types that implement
  `FromValue` must update their signature.
- Repeated list flag values are kept as separate elements and are no longer split on spaces, so
  `-H "A: 1" -H "B: 2"` reads as two elements. `--tags "a b"` is now one element; repeat the flag to pass several.
- `Command(suggest=...)` defaults to `True`.
- `Command` panics at construction on invalid declarations that used to misbehave at run time:
  - a required argument declared after an optional one,
  - a list argument declared before another argument,
  - duplicate flag names or shorthands, or a flag named like a built-in `help` or `version` flag.
- `Annotation` is now an enum with cases `required`, `required_as_group`, `one_required` and `mutually_exclusive`.
  It no longer has a `value` field or a fieldwise constructor.

### Added

- `FlagSet.require[T]` and `ArgSet.require[T]` return a value unwrapped, and raise an error that names the cause:
  an undefined name (with the closest match), a flag of another type, or a value that is unset with no default.
- `Array[T, N]` flags. Repeated values accumulate like a list flag, and exactly `N` must be given. Help shows the
  count, and zsh completion marks them repeatable. Positional `Array` arguments are rejected at compile time.
- `value_separator` for list and array flags, which splits a value read from the environment variable into
  elements and drops empty ones. Command line values are never split.
- A list argument declared last is variadic: it takes every remaining value and checks each against its type and
  `valid_values`. `Arg.new[List[T]]` accepts `valid_values` as plain elements, such as `["zsh", "bash"]`.
- Help shows value hints (`--port <int>`, `--tag <string>...`), `[env: VAR]`, and subcommand aliases, and sizes one
  column to fit every section.
- Zsh completion lists subcommand aliases.
- `OptType.display_name`, which spells list types as written in Mojo (`List[Int]`).
- Export `match_all` from the package.

### Changed

- Shorthand clusters follow POSIX: `-n5`, `-ao file`, `-aofile` and `-ao=file` parse, matching the longest
  shorthand at each position so multi-character shorthands still work in a cluster.
- Error messages name the flag and drop internal function names. Unknown shorthands get suggestions, compared
  case-insensitively.
- Flag values are validated before `pre_run` hooks, so `--port abc` is reported by flag name before any hook has
  side effects.
- Bash completion offers file names only after `String` and `List[String]` flags and for positional arguments of
  leaf commands, rather than wherever it had nothing else to offer. Zsh follows the same rule.
- A failing pre or post run hook reports one error, with its cause.
- `execute` is faster: it copies only the matched command path instead of the whole tree, and the parser looks
  each flag up once. On a 64-leaf tree with 22 flags per command, a nested `execute` went from ~42µs to ~5µs.
- `ParserState` is an enum, and flag parsing uses `match`.

### Fixed

- A bare `-` and negative numbers are values, not shorthands, both as positional arguments and as flag values
  (`--out -`). A digit shorthand the command defines still takes precedence.
- `read_args_from_stdin` splits like a shell: `--` and what follows are kept, `""` and quoted whitespace are
  arguments, and quotes can appear mid-argument (`--name="a b"`).
- In a mutually exclusive group, a flag passed on the command line no longer conflicts with another member that is
  set only by its environment variable.
- Running `execute` more than once no longer leaks parsed values or duplicate inherited flags between runs.
- An empty list default reads as an empty list, not `[""]`, and no longer fails to parse for numeric lists.
- `Arg.new[List[T]]` `valid_values` are matched per element. Each was stored as one joined list that no element
  could match.

## [0.4.2] - 2026-09-27

- Support Mojo 1.1.0.

[0.5.0]: https://github.com/thatstoasty/prism/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/thatstoasty/prism/releases/tag/v0.4.2
