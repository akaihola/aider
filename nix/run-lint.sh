#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"

errors=0

if [ -f pyproject.toml ]; then
    # This looks like a Python package.
    source ${INSTALL_IN_VIRTUALENV_CMD}

    run() {
        command -v "$1" && ( $@ || errors=$? )
    }

    source ${VENV}/bin/activate
    run darker
    run graylint
fi

for file in "$@"; do
    case "$file" in
        *.yml|*.yaml)
            run yamllint "$file"
            ;;
        *.sh|*.md|*.rst|*.txt)
            run codespell "$file"
            ;;
    esac
done

if [ -f Cargo.toml ]; then
  rustfmt --edition=2021 "$@"
  run cargo clippy
fi

if find -regex ".*\.\(m?j\|t\)s$" -print | grep -q .; then
  run eslint "$@"
fi

find -name "*.nix" -exec nix-instantiate --parse {} \+ >/dev/null || errors=$?

exit $errors
