#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=prism
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and example binaries."
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg
cp -a examples/. $TEMP_DIR
magic run mojo build $TEMP_DIR/aliases.mojo -o $TEMP_DIR/aliases
magic run mojo build $TEMP_DIR/hello_world.mojo -o $TEMP_DIR/hello_world
# magic run mojo build $TEMP_DIR/nested.mojo -o $TEMP_DIR/nested
# magic run mojo build $TEMP_DIR/printer.mojo -o $TEMP_DIR/printer
# magic run mojo build $TEMP_DIR/persistent_flags.mojo -o $TEMP_DIR/persistent
magic run mojo build $TEMP_DIR/fg_parent.mojo -o $TEMP_DIR/parent
magic run mojo build $TEMP_DIR/fg_child.mojo -o $TEMP_DIR/child
magic run mojo build $TEMP_DIR/arg_validators.mojo -o $TEMP_DIR/validators

echo "[INFO] Running examples..."
$TEMP_DIR/aliases my thing
$TEMP_DIR/hello_world say hello
# $TEMP_DIR/nested get cat --count 5 -l
# $TEMP_DIR/printer "sample-text" --formatting=underline
# $TEMP_DIR/persistent get cat --count 2 --lover
# $TEMP_DIR/persistent get dog -l
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

echo "[INFO] Cleaning up the example directory."
rm -R $TEMP_DIR
