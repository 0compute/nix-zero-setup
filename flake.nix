{

  description = "Nix Seed builds for GitHub Actions";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    artstd = {
      url = "path:/home/arthur/wrk/artdev/artstd";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        systems.follows = "systems";
        pyproject-nix.follows = "pyproject-nix";
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
    systems = {
      url = "github:nix-systems/default";
    };
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

      overlays.default = _final: _prev: { };

      lib = { inherit mkSeed; };

      apps =
        pkgs:
        let
          inherit (pkgs)
            docker
            coreutils
            jq
            oras
            skopeo
            ;
          inherit (inputs) self;
          name = "nix-seed";
          seed = mkSeed {
            inherit pkgs name;
            inherit self;
            selfFilter = drv: !lib.hasPrefix name (drv.name or "");
            tag = self.rev or self.dirtyRev or null;
          };
          tools = {
            seedLoad = pkgs.writeShellApplication {
              name = "seed-load";
              runtimeInputs = [ docker ];
              text = ''
                ${lib.getExe docker} load < ${seed}
              '';
            };
            verify = pkgs.writeShellApplication {
              name = "verify";
              runtimeInputs = [
                coreutils
                jq
                oras
                skopeo
              ];
              text = builtins.readFile ./bin/verify;
            };
            publish = pkgs.writeShellApplication {
              name = "publish";
              runtimeInputs = [ docker ];
              text = ''
                ${lib.getExe pkgs.nix} build .#seed
                ${lib.getExe docker} load < result
              '';
            };
          };
        in
        {
          publish = {
            type = "app";
            program = lib.getExe tools.publish;
          };
          seedLoad = {
            type = "app";
            program = lib.getExe tools.seedLoad;
          };
          verify = {
            type = "app";
            program = lib.getExe tools.verify;
          };
        };

      packages =
        pkgs:
        let
          inherit (pkgs)
            lib
            docker
            coreutils
            jq
            oras
            skopeo
            ;
          inherit (inputs) self;
          name = "nix-seed";
          seed = mkSeed {
            inherit pkgs name;
            inherit self;
            selfFilter = drv: !lib.hasPrefix name (drv.name or "");
            tag = self.rev or self.dirtyRev or null;
          };
          tools = {
            seedLoad = pkgs.writeShellApplication {
              name = "seed-load";
              runtimeInputs = [ docker ];
              text = ''
                ${lib.getExe docker} load < ${seed}
              '';
            };
            verify = pkgs.writeShellApplication {
              name = "verify";
              runtimeInputs = [
                coreutils
                jq
                oras
                skopeo
              ];
              text = builtins.readFile ./bin/verify;
            };
          };
        in
        {
          inherit seed;
          default = seed;
          inherit (tools) seedLoad verify;
        };

      checks =
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          attrs = { inherit pkgs mkSeed; };
          runFtest = builtins.getEnv "CI" != "true";
          suites = {
            utest = import ./tests/unit.nix attrs;
            ftest =
              if runFtest then
                import ./tests/functional.nix attrs
              else
                pkgs.runCommand "ftest-skipped" { } "touch $out";
            bats = pkgs.runCommand "bats-tests" {
              nativeBuildInputs = with pkgs; [ bats ];
              src = ./.;
            } ''
              cd "$src"
              ${lib.getExe pkgs.bats} tests/bin
              touch $out
            '';
            examples = import ./tests/examples.nix (
              attrs
              // {
                inherit system;
                inherit (inputs) flake-utils pyproject-nix;
              }
            );
          };
        in
        suites;

    };

}
