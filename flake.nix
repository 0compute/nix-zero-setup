{

  description = "Nix Flakes, baked. Accept no substitute.";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    artstd = {
      url = "github:0compute/artstd";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        nix-seed.inputs = {
          flake-utils.follows = "flake-utils";
          nixpkgs.follows = "nixpkgs";
          pyproject-nix.follows = "pyproject-nix";
          systems.follows = "systems";
        };
        systems.follows = "systems";
      };
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (inputs.artstd.lib) flakeSet;
      mkSeed = import ./mkseed.nix;
    in
    flakeSet {

      inherit (inputs) self;

      lib = { inherit mkSeed; };

      apps = pkgs: {

        publish = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "publish";
              runtimeInputs = with pkgs; [
                docker
                gnutar
                gzip
                jq
                cosign
              ];
              text = builtins.readFile ./bin/publish;
            }
          );
        };

        verify = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "verify";
              runtimeInputs = with pkgs; [
                coreutils
                jq
                oras
                skopeo
              ];
              text = builtins.readFile ./bin/verify;
            }
          );
        };
      };

      packages =
        pkgs:
        let
          inherit (inputs) self;
          name = "nix-seed";
          seed = mkSeed {
            inherit name pkgs self;
            selfFilter =
              drv:
              let
                # CHECK: needs the or?
                drvName = drv.name or "";
              in
              !(builtins.any (name: lib.hasPrefix name drvName) [
                # filter self from seed otherwise this is circular
                name
                # filter examples since we want them built in check
                "examples"
              ]);
            # no rev when using `nix build path:.`
            tag = self.rev or self.dirtyRev or null;
          };
        in
        {
          default = seed;
          inherit seed;
        };

      checks =
        pkgs:
        let
          attrs = { inherit pkgs mkSeed; };
        in
        {

          nix-unit = import ./tests/unit.nix attrs;

          nix-functional = import ./tests/functional.nix attrs;

          bash =
            pkgs.runCommand "bats-tests"
              {
                nativeBuildInputs = with pkgs; [ bats ];
                src = ./.;
              }
              ''
                cd "$src"
                ${lib.getExe pkgs.bats} tests/bin | tee $out
              '';

          examples = import ./tests/examples.nix (
            attrs // { inherit (inputs) flake-utils pyproject-nix; }
          );

        };
    };

}
