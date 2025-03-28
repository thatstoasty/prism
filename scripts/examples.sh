#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=prism
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and example binaries."
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg
cp -a examples/. $TEMP_DIR
magic run mojo build $TEMP_DIR/aliases.mojo -o $TEMP_DIR/aliases
magic run mojo build $TEMP_DIR/hello_world.mojo -o $TEMP_DIR/hello_world
magic run mojo build $TEMP_DIR/fg_parent.mojo -o $TEMP_DIR/parent
magic run mojo build $TEMP_DIR/fg_child.mojo -o $TEMP_DIR/child
magic run mojo build $TEMP_DIR/arg_validators.mojo -o $TEMP_DIR/validators
magic run mojo build $TEMP_DIR/alt_flag_values.mojo -o $TEMP_DIR/alt_flag_values
magic run mojo build $TEMP_DIR/flag_action.mojo -o $TEMP_DIR/flag_action
magic run mojo build $TEMP_DIR/list_flags.mojo -o $TEMP_DIR/list_flags
magic run mojo build $TEMP_DIR/version.mojo -o $TEMP_DIR/version
magic run mojo build $TEMP_DIR/exit.mojo -o $TEMP_DIR/exit
magic run mojo build $TEMP_DIR/multiple_bool_flag.mojo -o $TEMP_DIR/multiple_bool_flag

echo "[INFO] Running examples..."
# Need to run these first examples as part of a mojo project as they have external dependencies.
# printer is a portable binary, but nested and persistent_flags are not because they depend on a python library.
# cd examples/printer
# magic run mojo build printer.mojo
# ./printer "sample-text" --formatting=underline

# cd ../requests
# magic run mojo build nested.mojo
# magic run nested get cat --count 3 -l
# magic run mojo build persistent_flags.mojo -o persistent
# magic run persistent get cat --count 2 --lover
# magic run persistent get dog

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


echo "[INFO] Cleaning up the example directory."
rm -R $TEMP_DIR