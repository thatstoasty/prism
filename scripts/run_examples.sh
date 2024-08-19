#!/bin/bash

check_out_remote_module() (
    rurl="$1"
    shift
    declare -a paths
    declare -a module_names
    for var in "$@"
    do
        IFS="="
        read -ra module_name_components <<< "$var"
        components_count=${#module_name_components[@]}
        path=${module_name_components[0]}
        module_name=${module_name_components[$components_count-1]}
        paths=("${paths[@]}" "$path")
        module_names=("${module_names[@]}" "$module_name")
    done
    IFS=" "

    for module_name in "${module_names[@]}"
    do
        rm -rf ../$module_name
    done

    current_date_time=$(date)
    echo "URL: $rurl"
    git clone -n --depth=1 --filter=tree:0 $rurl
    cd ${rurl##*/}
    git sparse-checkout set --no-cone "${paths[@]}"
    git checkout

    for i in "${!paths[@]}"
    do
        module_name=${module_names[$i]}
        path=${paths[$i]}
        cp -R ./$path ../../$module_name
    done
    cd ../
)

checkout_dependencies()(
    echo -e "\n[INFO] Checking out dependencies"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/gojo" "gojo"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/hue" "hue"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/mist" "mist"
)

build_dependencies() {
    echo -e "\n[INFO] Building dependencies"
    mojo package gojo -o $TEMP_DIR/gojo.mojopkg
    mojo package hue -o $TEMP_DIR/hue.mojopkg
    mojo package mist -o $TEMP_DIR/mist.mojopkg
    rm -R gojo
    rm -R hue
    rm -R mist
}

get_dependencies() {
    echo -e "\n[INFO] Getting dependencies"
    mkdir -p "_deps"
    cd "_deps"

    checkout_dependencies
    cd ..

    rm -rf "_deps"
    build_dependencies
}

export MOJO_PYTHON_LIBRARY=$(which python3)
TEMP_DIR=~/tmp
CURRENT_DIR=$(pwd)
mkdir -p $TEMP_DIR

echo -e "Building the prism package..."
bash scripts/build.sh package
mv prism.mojopkg $TEMP_DIR

echo -e "Building the example dependencies...\n"
get_dependencies # printer uses mist, so it needs the mist package

echo -e "Building binaries for all examples...\n"
cp -a ./examples/* $TEMP_DIR/
cd $TEMP_DIR
rm __init__.mojo

mojo build aliases.mojo -o aliases
mojo build hello_world.mojo -o hello_world
mojo build nested.mojo -o nested
mojo build printer.mojo -o printer
mojo build persistent_flags.mojo -o persistent
mojo build fg_parent.mojo -o parent
mojo build fg_child.mojo -o child
mojo build arg_validators.mojo -o validators

echo -e "Executing examples...\n"
echo -e "[INFO] Example: Aliases"
./aliases my thing

echo -e "\n[INFO] Example: Say Hello"
./hello_world say hello

echo -e "\n[INFO] Example: Nested Commands"
./nested get cat --count 5 -l

echo -e "\n[INFO] Example: Color Printer"
./printer "sample-text" --formatting=underline

echo -e "\n[INFO] Example: Persistent Flags"
./persistent get cat --count 2 --lover
./persistent get dog -l

echo -e "\n[INFO] Example: Parent Command"
./parent --required --host=www.example.com --port 8080
./parent --required --host www.example.com
./parent --required --host www.example.com --uri abcdef --port 8080
./parent

echo -e "\n[INFO] Example: Child Command"
./child tool --required -a --host=www.example.com --port 8080
./child tool --required -a --host www.example.com
./child tool --required --also --host www.example.com --uri abcdef --port 8080

echo -e "\n[INFO] Example: Arg Validators"
./validators Hello from Mojo!
./validators no_args Hello from Mojo!
./validators valid_args Hello from Mojo!
./validators minimum_n_args Hello from Mojo!
./validators maximum_n_args Hello from Mojo!
./validators exact_args Hello from Mojo!
./validators range_args Hello from Mojo!

cd $CURRENT_DIR
rm -R $TEMP_DIR
