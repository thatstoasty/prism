#!/bin/bash

mojo run examples/hello_world/root.mojo say hello
mojo run examples/nested/nested.mojo get cat --count 5 -l
mojo run examples/printer/printer.mojo "sample-text" --formatting=underline
mojo run examples/read_csv/root.mojo --file examples/read_csv/file.csv --lines 1
mojo run examples/logging/root.mojo --type=json hello
mojo run examples/persistent_flags_and_cmds/persistent.mojo get cat --count 2 --lover
mojo run examples/persistent_flags_and_cmds/persistent.mojo get dog --count 2 -l
