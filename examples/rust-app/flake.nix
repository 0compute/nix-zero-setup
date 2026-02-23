{
  description = "Example Rust project using nix-seed";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-seed = {
      url = "github:your-org/nix-seed";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        default = pkgs.rustPlatform.buildRustPackage {
          pname = "rust-app";
          version = "0.1.0";
          src = ./.;
          # in a real project, this would be a hash or a generated file
          cargoLock.lockFile = ./Cargo.lock;
        };
      in
      {
        packages = {
          inherit default;
          seed = inputs.nix-seed.lib.mkSeed {
            inherit pkgs;
            name = "rust-build-env";
            contents = with pkgs; [
              rust-analyzer
              clippy
            ];
          };
        };
      }
    );
}
