{
  description = "GitHub workflow example project using nix-seed";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-seed = { url = "path:../.."; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        examplePkg = pkgs.callPackage ./default.nix { };
        seed =
          inputs.nix-seed.lib.mkSeed {
            inherit pkgs;
            name = "github-example-seed";
          };
      in
      {
        packages = {
          default = examplePkg;
          verify = inputs.nix-seed.packages.${system}.verify;
          seed = seed // {
            run = "${pkgs.lib.getExe pkgs.docker} load < ${seed}";
          };
        };

        apps.verify = {
          type = "app";
          program = pkgs.lib.getExe inputs.nix-seed.packages.${system}.verify;
        };
      }
    );
}
