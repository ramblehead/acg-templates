{
  description = "A Nix-flake-based Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [
          (final: prev: {
            python = prev.python314;
            nodejs = prev.nodejs_24;
          })
        ];
        pkgs = import nixpkgs {inherit overlays system;};
        packages = with pkgs; [
          python
          uv
          git
          typos
          alejandra
        ];
      in {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              typos = {
                enable = true; # Source code spell checker
                settings = {
                  write = true; # Automatically fix typos
                  ignored-words = [];
                };
              };
              alejandra.enable = true; # Nix linter & formatter
            };
          };
        };

        devShells.default = pkgs.mkShell {
          inherit packages;

          shellHook = ''
            echo "`${pkgs.python}/bin/python --version`"
            # echo "Node.js `${pkgs.nodejs}/bin/node --version`"
            ${self.checks.${system}.pre-commit-check.shellHook}
          '';
        };
      }
    );
}
