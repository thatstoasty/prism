#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=prism
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and example binaries."
pixi run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg
cp -a examples/. $TEMP_DIR
pixi run mojo build $TEMP_DIR/aliases.mojo -o $TEMP_DIR/aliases
pixi run mojo build $TEMP_DIR/hello_world.mojo -o $TEMP_DIR/hello_world
pixi run mojo build $TEMP_DIR/fg_parent.mojo -o $TEMP_DIR/parent
pixi run mojo build $TEMP_DIR/fg_child.mojo -o $TEMP_DIR/child
pixi run mojo build $TEMP_DIR/arg_validators.mojo -o $TEMP_DIR/validators
pixi run mojo build $TEMP_DIR/alt_flag_values.mojo -o $TEMP_DIR/alt_flag_values
pixi run mojo build $TEMP_DIR/flag_action.mojo -o $TEMP_DIR/flag_action
pixi run mojo build $TEMP_DIR/list_flags.mojo -o $TEMP_DIR/list_flags
pixi run mojo build $TEMP_DIR/version.mojo -o $TEMP_DIR/version
pixi run mojo build $TEMP_DIR/exit.mojo -o $TEMP_DIR/exit
pixi run mojo build $TEMP_DIR/multiple_bool_flag.mojo -o $TEMP_DIR/multiple_bool_flag
pixi run mojo build $TEMP_DIR/stdin.mojo -o $TEMP_DIR/stdin
pixi run mojo build $TEMP_DIR/suggest.mojo -o $TEMP_DIR/suggest
pixi run mojo build $TEMP_DIR/full_api.mojo -o $TEMP_DIR/full_api


echo "[INFO] Running examples..."
# Need to run these first examples as part of a mojo project as they have external dependencies.
# printer is a portable binary, but nested and persistent_flags are not because they depend on a python library.
# cd examples/printer
# pixi run mojo build printer.mojo
# ./printer "sample-text" --formatting=underline

# cd ../requests
# pixi run mojo build nested.mojo
# pixi run nested get cat --count 3 -l
# pixi run mojo build persistent_flags.mojo -o persistent
# pixi run persistent get cat --count 2 --lover
# pixi run persistent get dog

cd ../..

$TEMP_DIR/aliases my thing
$TEMP_DIR/hello_world say hello
$TEMP_DIR/parent --required --host=www.example.com --port 8080
$TEMP_DIR/parent --required --host www.example.com
$TEMP_DIR/parent --required --host www.example.com --uri abcdef --port 8080
$TEMP_DIR/parent
$TEMP_DIR/child tool --required -a --host=www.example.com --port 8080
$TEMP_DIR/child tool --required -a --host www.example.com
$TEMP_DIR/child tool --required --also --host www.example.com --uri abcdef --port 8080
$TEMP_DIR/validators Hello from Mojo!
$TEMP_DIR/validators no_args Hello from Mojo!
$TEMP_DIR/validators valid_args Hello from Mojo!
$TEMP_DIR/validators minimum_n_args Hello from Mojo!
$TEMP_DIR/validators maximum_n_args Hello from Mojo!
$TEMP_DIR/validators exact_args Hello from Mojo!
$TEMP_DIR/validators range_args Hello from Mojo!
$TEMP_DIR/alt_flag_values -n Mojo
$TEMP_DIR/alt_flag_values
$TEMP_DIR/flag_action
$TEMP_DIR/flag_action -n Mojo
$TEMP_DIR/list_flags
$TEMP_DIR/list_flags -n My -n Mojo
$TEMP_DIR/list_flags sum -n 1 -n 2 -n 3 -n 4 -n 5
$TEMP_DIR/list_flags sum_float -n 1.2 -n 2.3 -n 3.4 -n 4.5 -n 5.6
$TEMP_DIR/version -v
$TEMP_DIR/version --version
$TEMP_DIR/exit || echo "Exit Code: $?"
$TEMP_DIR/multiple_bool_flag -r0vvas
$TEMP_DIR/multiple_bool_flag -r0vas
$TEMP_DIR/multiple_bool_flag -r0a --verbose "Hello Mojo!"
echo "Hello Python!" | $TEMP_DIR/stdin examples/stdin.mojo "Hello Mojo!"
$TEMP_DIR/suggest --gelp
$TEMP_DIR/full_api
$TEMP_DIR/full_api connect -r0a --verbose --host 192.168.1.1
$TEMP_DIR/full_api --gelp
$TEMP_DIR/full_api allow -r0
$TEMP_DIR/full_api allow -hl localhost -hl 192.168.1.1 -r0
$TEMP_DIR/full_api allow -hl localhost -hl 192.168.1.2 -r0


echo "[INFO] Cleaning up the example directory."
rm -R $TEMP_DIR
