#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=prism
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and copying tests."
cp -a test/. $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg

echo "[INFO] Running tests..."
magic run mojo test $TEMP_DIR

echo "[INFO] Cleaning up the test directory."
rm -R $TEMP_DIR
