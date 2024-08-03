{
  description = "Flake providing dev shell for using aider-chat in NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python3;
        buildInputs = with pkgs; [
          pkgs.libsecret  # for secret-tool to manage API keys
          pkgs.nodejs  # for ESLint

          (pkgs.python3.withPackages (ps: with ps; [
            # https://aider.chat/docs/install/optional.html#enable-playwright
            # https://nixos.wiki/wiki/Playwright
            playwright  # instead of letting Aider install it
            playwright-driver
            playwright-driver.browsers
          ]))

          pkgs.wl-clipboard
          pkgs.xclip
        ];
        envVars = {
          # https://discourse.nixos.org/t/how-to-solve-libstdc-not-found-in-shell-nix/25458
          LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib";

          # https://aider.chat/docs/install/optional.html#enable-playwright
          # https://nixos.wiki/wiki/Playwright
          PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
          PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
          # https://github.com/microsoft/playwright/issues/5501
          PLAYWRIGHT_NODEJS_PATH = "${pkgs.nodejs}/bin/node";

          AIDER_LINT_CMD = "${./nix/run-lint.sh}";
          AIDER_TEST_CMD = "${./nix/run-tests.sh}";
        };

        # Function to create a string of export statements
        makeExportScript = vars: pkgs.lib.concatStrings (
          pkgs.lib.mapAttrsToList (name: value: "export ${name}=${pkgs.lib.escapeShellArg value}\n") vars
        );

        # Create a shell script that exports the variables
        exportEnvironmentVariables = pkgs.writeShellScript "export-env-vars" (makeExportScript envVars);

        environmentSetupScript = ''
          source ${exportEnvironmentVariables}
          ENV="''${AIDER_ENV_DIR:-''${XDG_CACHE_HOME:-''${HOME}/.cache}/aider-chat}"
          echo Aider environment is in ''${ENV}
          VENV=$ENV/.venv
          export NPM_CONFIG_PREFIX=$ENV/.npm-global
          if [ ! -d $VENV ]; then
            python -m venv $VENV
          fi
          source $VENV/bin/activate
          export PATH=$NPM_CONFIG_PREFIX/bin:${./nix}:$PATH
          echo  # an empty line before usage instructions
        '';
      in
      {
        url = self.sourceInfo.url;

        apps = {
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "aider" ''
              ${environmentSetupScript}
              ${pkgs.lib.concatMapStrings (pkg: "export PATH=${pkg}/bin:$PATH\n") buildInputs}
              grep -B100 "^Once" ${./nix/usage.md} | head --lines=-1
              exec aider "$@"
            '';
          };
          install = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "aider-install" ''
              ${environmentSetupScript}
              ${pkgs.lib.concatMapStrings (pkg: "export PATH=${pkg}/bin:$PATH\n") buildInputs}
              exec aider-install
            '';
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = buildInputs;
          shellHook = ''
            ${environmentSetupScript}
            cat ${./nix/usage.md}
            exec zsh
          '';
        };
      });
}
