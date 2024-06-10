#!/bin/bash
export MOJO_PYTHON_LIBRARY=$(which python3)

mkdir ./temp
mojo package prism -I ./external -o ./temp/prism.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/aliases/root.mojo -o temp/aliases
mojo build examples/hello_world/root.mojo -o temp/hello_world
# mojo build examples/nested/nested.mojo -o temp/nested
mojo build examples/printer/printer.mojo -o temp/printer
# mojo build examples/persistent/root.mojo -o temp/persistent
mojo build examples/flag_groups/parent.mojo -o temp/parent
mojo build examples/flag_groups/child.mojo -o temp/child
mojo build examples/arg_validators/root.mojo -o temp/validators

echo -e "Executing examples...\n"
cd temp
./aliases my thing
./hello_world say hello
# ./nested get cat --count 5 -l
./printer "sample-text" --formatting=underline
# ./persistent get cat --count 2 --lover
# ./persistent get dog -l
./parent --required --host=www.example.com --port 8080
./parent --required --host www.example.com
./parent --required --host www.example.com --uri abcdef --port 8080
./parent
./child tool --required -a --host=www.example.com --port 8080
./child tool --required -a --host www.example.com
./child tool --required --also --host www.example.com --uri abcdef --port 8080
./validators Hello from Mojo!
./validators no_args Hello from Mojo!
./validators valid_args Hello from Mojo!
./validators minimum_n_args Hello from Mojo!
./validators maximum_n_args Hello from Mojo!
./validators exact_args Hello from Mojo!
./validators range_args Hello from Mojo!

cd ..
rm -R ./temp
