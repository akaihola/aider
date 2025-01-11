#!/usr/bin/env bash

# This script creates a virtualenv `.venv` in the current directory,
# assuming it's at the root of a Python package source tree.
# It then installs the package in editable mode with all of its extras (if any).
# This script is used in `run-lint.sh` and `run-tests.sh`.

# Create a virtualenv if it doesn't exist
uv venv

# Install the package in editable mode with all of its extras (if any).
uv pip compile --all-extras pyproject.toml | uv pip install -r - -e .
