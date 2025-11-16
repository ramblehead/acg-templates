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

        runtimePackages = with pkgs; [
          python
          uv
          git
          typos
          alejandra
        ];

        runtimeLibs = with pkgs; [
          stdenv.cc.cc
          # stdenv.cc.cc.lib # libstdc++, libgcc_s
          # glibc # libc, ld-linux, …
          # zlib
          # openssl
          # libuuid
          # curl
          # icu
          # libffi
          # expat
          # bzip2
          # xz
          # # lzma
          # attr
          # acl
          # libxcrypt
          # Add more if you hit a missing .so (see `ldd` later)
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

        devShells.default = pkgs.mkShell rec {
          packages = runtimePackages;

          NIX_LD =
            pkgs.lib.strings.trim
            (builtins.readFile "${pkgs.stdenv.cc}/nix-support/dynamic-linker");

          NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
          LD_LIBRARY_PATH = NIX_LD_LIBRARY_PATH;

          shellHook = ''
            echo "''$(${pkgs.python}/bin/python --version)"
            echo "Using NIX_LD=$NIX_LD"

            ${self.checks.${system}.pre-commit-check.shellHook}
          '';
        };
      }
    );
}
