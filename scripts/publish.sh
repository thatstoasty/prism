#!/bin/bash

# ignore errors because we want to ignore duplicate packages
for file in $CONDA_BLD_PATH/**/*.conda; do
    magic run rattler-build upload prefix -c "mojo-community" "$file" || true
done
