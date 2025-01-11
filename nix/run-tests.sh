#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"

errors=0

if [ -f pyproject.toml ]; then
    # This looks like a Python package.
    source ${INSTALL_IN_VIRTUALENV_CMD}

    # Run pytest if it's available.
    if command -v pytest &> /dev/null; then
        pytest || errors=$?
    fi
fi

if [ -f Cargo.toml ]; then
    cargo test || errors=$?
fi

exit $errors
