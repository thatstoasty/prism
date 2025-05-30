# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [0.3.0] - 2024-01-02

- Refactored the `Command` API to define everything up front similar to `urfave/cli`.
  - This is a big change to how the library works, users should review the examples and readme to see how to use the new API.
- Removed usage of the `FlagSet` struct and moved to functions that operate on `List[Flag]`.

## [0.2.1] - 2024-11-02

- Added environment variable and file path support for flags.
- Added action support for flags.
- Added `StringList`, `IntList`, `Float64List` `Flag` types.

## [0.2.0] - 2024-10-09

- Refactor flag get/parsing to use ref to simplify code and enable removal of transform module.
- Renamed some fields to make them more accurate in the Command struct.

## [0.1.7] - 2024-10-09

- Fix command parsing bug.
- Change `context` to `ctx` to reduce visual noise.

## [0.1.6] - 2024-10-06

- Switch to using a cli context as the command argument.
- Refactor code to reduce copies of commands instead using `Arc[Command]` generally.
- Add example projects.

## [0.1.4] - 2024-10-05

- Refactor code to split out functionality into separate files and classes.
- Reduced copying of structs.

## [0.1.3] - 2024-09-19

- Introduce `mog` dependency for help function formatting.

## [0.1.2] - 2024-09-13

- First release with a changelog! Added rattler build and conda publish.
