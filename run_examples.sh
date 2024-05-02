#!/bin/bash
export MOJO_PYTHON_LIBRARY=$(which python3)

mkdir ./temp
mojo package prism -I ./external -o ./temp/prism.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/aliases/root.mojo -o temp/aliases
mojo build examples/hello_world/root.mojo -o temp/hello_world
mojo build examples/nested/nested.mojo -o temp/nested
mojo build examples/printer/printer.mojo -o temp/printer
mojo build examples/read_csv/root.mojo -o temp/read_csv
mojo build examples/logging/root.mojo -o temp/logging
mojo build examples/persistent/root.mojo -o temp/persistent
mojo build examples/flag_groups/root.mojo -o temp/my
mkdir -p temp/examples/read_csv/ && cp examples/read_csv/file.csv temp/examples/read_csv/file.csv

echo -e "Executing examples...\n"
cd temp
./aliases my thing
./hello_world say hello
# ./nested get cat --count 5 -l
./printer "sample-text" --formatting=underline
./read_csv --file examples/read_csv/file.csv --lines 1
./logging --type=json hello
# ./persistent get cat --count 2 --lover
./persistent get dog -l
./my tool --color "#ffffff" --formatting "underline" --hue "red" --required
./my tool --color "#ffffff" --required
./my tool
./my tool --host "www.example.com" --port "8080" --free --required
./my tool --host "www.example.com" --free --required
./my tool --host "www.example.com" --uri "/api/v1" --free --required

cd ..
rm -R ./temp
