#!/bin/bash
export MOJO_PYTHON_LIBRARY=$(which python)

mkdir ./temp
mojo package prism -I ./external -o ./temp/prism.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/hello_world/root.mojo -o temp/hello_world
mojo build examples/nested/nested.mojo -o temp/nested
mojo build examples/printer/printer.mojo -o temp/printer
mojo build examples/read_csv/root.mojo -o temp/read_csv
mojo build examples/logging/root.mojo -o temp/logging
mojo build examples/persistent_flags_and_cmds/persistent.mojo -o temp/persistent
mkdir -p temp/examples/read_csv/ && cp examples/read_csv/file.csv temp/examples/read_csv/file.csv

echo -e "Executing examples...\n"
cd temp
./hello_world say hello
./nested get cat --count 5 -l
./printer "sample-text" --formatting=underline
./read_csv --file examples/read_csv/file.csv --lines 1
./logging --type=json hello
./persistent get cat --count 2 --lover
./persistent get dog -l

cd ..
rm -R ./temp
