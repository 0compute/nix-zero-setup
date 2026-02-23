{
  description = "Example Python ML project using pyproject.nix and nix-seed";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        python = pkgs.python3;
        pythonEnv = python.withPackages (
          (inputs.pyproject-nix.lib.project.loadPyproject { projectRoot = ./.; })
          .renderers.withPackages
            { inherit python; }
        );
      in
      {
        packages = {
          default = pythonEnv;

          seed = inputs.nix-seed.lib.mkSeed {
            inherit pkgs;
            name = "ml-build-env";
            contents = with pkgs; [ hatch ];
          };
        };
      }
    );
}
