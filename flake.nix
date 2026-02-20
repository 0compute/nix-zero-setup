{

  description = "Zero-setup Nix builds for GitHub actions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      mkBuildContainer = import ./mkbuildcontainer.nix;
    in
    {
      lib = { inherit mkBuildContainer; };
    }
    // inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let

        pkgs = inputs.nixpkgs.legacyPackages.${system};
        name = "nix-zero-setup";

        nix-build-container = mkBuildContainer {
          inherit pkgs name;
          flake = inputs.self;
          # Exclude container itself to avoid circular dependency
          flakeFilter = drv: !pkgs.lib.hasPrefix name (drv.name or "");
          tag = inputs.self.rev or inputs.self.dirtyRev or null;
        };

      in
      {

        checks =
          let
            attrs = { inherit pkgs mkBuildContainer; };
          in
          {
            utest = import ./tests/unit.nix attrs;
            ftest = import ./tests/functional.nix attrs;
            examples = import ./tests/examples.nix (
              attrs
              // {
                inherit system;
                inherit (inputs) flake-utils pyproject-nix;
              }
            );
          };

        packages = {
          inherit nix-build-container;
          default = nix-build-container;
        };

      }
    );

}
