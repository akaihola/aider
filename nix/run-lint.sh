#!/usr/bin/env bash

errors=0

run() {
    command -v uv >/dev/null && uv pip show --quiet "$1" && ( uv run $@ || errors=$? )
}

if [ -f pyproject.toml ]; then
    # This looks like a Python package.
    uv sync --quiet --all-groups --all-extras
    UV_PYTHON=.venv
    run darker
    run graylint
fi

for file in "$@"; do
    case "$file" in
        *.yml|*.yaml)
            uvx yamllint "$file" || errors=$?
            ;;
        *.sh|*.md|*.rst|*.txt)
            uvx codespell "$file" || errors=$?
            ;;
    esac
done

if [ -f Cargo.toml ]; then
  rustfmt --edition=2021 "$@" || errors=$?
  run cargo clippy || errors=$?
fi

if find -regex ".*\.\(m?j\|t\)s$" -print | grep -q .; then
  command -v eslint && eslint "$@" || errors=$?
fi

find -name "*.nix" -exec nix-instantiate --parse {} \+ >/dev/null || errors=$?

exit $errors
