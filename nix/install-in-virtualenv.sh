#!/usr/bin/env bash

# This script creates a virtualenv `.venv` in the current directory,
# assuming it's at the root of a Python package source tree.
# It then installs the package in editable mode with all of its extras (if any).
# This script is used in `run-lint.sh` and `run-tests.sh`.

# Define locations for a virtualenv and the pip binary within.
VENV=.venv
PIP=${VENV}/bin/pip

# Create a virtualenv if it doesn't exist and upgrade pip (to suppress upgrade warnings).
[ ! -f ${PIP} ] && python -m venv ${VENV} && ${PIP} install -U pip

# Install the package in editable mode with all of its extras (if any).
EXTRAS=$(\
  ${PIP} install --quiet --report=- --editable="." \
  | jq --raw-output '.install[0].metadata.provides_extra|join(",")' 2> /dev/null \
)
[ -n "${EXTRAS}" ] && ${PIP} install --editable=".[${EXTRAS}]"
