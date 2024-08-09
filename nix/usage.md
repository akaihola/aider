In your regular shell, you can type:

    cd /path/to/aider-chat ; nix run '.#install'  # to install Aider and dependencies
    nix run '/path/to/aider-chat'                 # to run Aider
    nix develop '/path/to/aider-chat'             # drop to a shell in the Aider environment

Once dropped into a shell in the Aider environment, you can type:

    cd /path/to/aider-chat ; aider-install  # to install Aider and dependencies
                                            #   in $AIDER_ENV_DIR or ~/.cache/aider-chat
    aider                                   # to run Aider

To make an editable Python package install, define `AIDER_EDITABLE=1`
in the environment before running `aider-install`.
