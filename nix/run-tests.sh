#!/usr/bin/env bash

errors=0

if [ -f pyproject.toml ]; then
    # This looks like a Python package.
    uv sync --all-groups --all-extras
    UV_PYTHON=.venv

    # Run pytest if it's available.
    if uv pip show --quiet pytest; then
        uv run pytest || errors=$?
    fi
fi

if [ -f Cargo.toml ]; then
    cargo test || errors=$?
fi

exit $errors
