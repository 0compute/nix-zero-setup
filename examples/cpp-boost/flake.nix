{
  description = "Example C++ project using Boost and nix-seed";

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
        default = pkgs.stdenv.mkDerivation {
          pname = "cpp-boost-example";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = with pkgs; [
            cmake
            ninja
          ];
          buildInputs = with pkgs; [ boost ];
        };
      in
      {
        packages = {
          inherit default;
          seed = inputs.nix-seed.lib.mkSeed {
            inherit pkgs;
            name = "cpp-boost-build-env";
            contents = with pkgs; [ gcc ];
          };
        };
      }
    );
}
