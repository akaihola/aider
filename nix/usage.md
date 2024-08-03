In your regular shell, you can type:

    nix run '/path/to/flake-aider-chat#install'  # to install Aider and dependencies
    nix run '/path/to/flake-aider-chat'          # to run Aider
    nix develop '/path/to/flake-aider-chat'      # drop to a shell in the Aider environment

Once dropped into a shell in the Aider environment, you can type:

    aider-install  # to install Aider and dependencies to $AIDER_ENV_DIR or ~/.cache/aider-chat
    aider          # to run Aider

To make an editable Python package install, define `AIDER_EDITABLE=1`
in the environment before running `aider-install`.
