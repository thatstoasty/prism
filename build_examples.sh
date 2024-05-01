#!/bin/bash
export MOJO_PYTHON_LIBRARY=$(which python3)


echo -e "Building binaries for all examples...\n"
mojo build examples/aliases/root.mojo                           -o examples/aliases
mojo build examples/hello_world/root.mojo                       -o examples/hello_world
mojo build examples/hello_chromeria/root.mojo                   -o examples/aliases/hello_chromeria
mojo build examples/nested/nested.mojo                          -o examples/nested
mojo build examples/printer/printer.mojo                        -o examples/printer
mojo build examples/read_csv/root.mojo                          -o examples/read_csv
mojo build examples/logging/root.mojo                           -o examples/logging
mojo build examples/persistent/root.mojo                        -o examples/persistent
mojo build examples/flag_groups/root.mojo                       -o examples/my

sleep 5

echo -e "Generating tapes...\n"
