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
          inherit (inputs) self;
          name = "nix-seed";
          seed = mkSeed {
            inherit pkgs name;
            inherit self;
            selfFilter = drv: !lib.hasPrefix name (drv.name or "");
            tag = self.rev or self.dirtyRev or null;
          };
          tools = {
            verify = pkgs.writeShellApplication {
              name = "verify";
              runtimeInputs = with pkgs; [
                coreutils
                jq
                oras
                skopeo
              ];
              text = builtins.readFile ./bin/verify;
            };
            publish = pkgs.writeShellApplication {
              name = "publish";
              runtimeInputs = with pkgs; [ docker ];
              text = ''
                nix build .#seed
                docker load < result
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
          inherit (inputs) self;
          name = "nix-seed";
          seed = mkSeed {
            inherit name pkgs self;
            # filter self from seed otherwise this is circular
            # CHECK: needs the or?
            selfFilter = drv: !lib.hasPrefix name (drv.name or "");
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
              attrs // { inherit (inputs) flake-utils pyproject-nix; }
            );
          };
        in
        suites;

    };

}
