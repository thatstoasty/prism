# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

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
