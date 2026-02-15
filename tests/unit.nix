{ pkgs }:
let
  inherit (pkgs) lib;
  nixZeroSetupLib = import ../lib.nix;

  results = lib.runTests {
    testEnvConfig = {
      expr = lib.sort (a: b: a < b) (nixZeroSetupLib.mkBuildContainer {
        inherit pkgs;
        inputsFrom = [ pkgs.hello ];
        nixConf = "extra-features = nix-command";
      }).config.Env;
      expected = lib.sort (a: b: a < b) [
        "USER=root"
        "NIX_CONFIG=sandbox = false\nbuild-users-group =\nextra-features = nix-command\n"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PATH=/bin:/usr/bin:/sbin:/usr/sbin"
      ];
    };

    testDefaultName = {
      expr =
        (nixZeroSetupLib.mkBuildContainer {
          inherit pkgs;
          inputsFrom = [ pkgs.hello ];
        }).name;
      expected = "hello-build-container.tar.gz";
    };

    testCustomName = {
      expr =
        (nixZeroSetupLib.mkBuildContainer {
          inherit pkgs;
          name = "custom";
        }).name;
      expected = "custom.tar.gz";
    };

    testInputsFromMerging = {
      expr =
        let
          drv1 = pkgs.stdenv.mkDerivation {
            pname = "test1";
            version = "1.0";
            buildInputs = with pkgs; [ hello ];
          };
          drv2 = pkgs.stdenv.mkDerivation {
            pname = "test2";
            version = "1.0";
            nativeBuildInputs = with pkgs; [ ripgrep ];
          };
          container = nixZeroSetupLib.mkBuildContainer {
            inherit pkgs;
            inputsFrom = [
              drv1
              drv2
            ];
            contents = with pkgs; [ jq ];
          };
        in
        container.contents;
      expected = with pkgs; [
        nixVersions.latest
        bashInteractive
        cacert
        coreutils
        git
        hello
        ripgrep
        jq
      ];
    };

    testContentsMerging = {
      expr =
        let
          drv = pkgs.stdenv.mkDerivation {
            pname = "test";
            version = "1.0";
            buildInputs = with pkgs; [ hello ];
          };
          container = nixZeroSetupLib.mkBuildContainer {
            inherit pkgs;
            inputsFrom = [ drv ];
            contents = with pkgs; [ jq ];
          };
        in
        container.contents;
      expected = with pkgs; [
        nixVersions.latest
        bashInteractive
        cacert
        coreutils
        git
        hello
        jq
      ];
    };
  };
in
if results == [ ] then
  pkgs.runCommand "unit-tests" { } "touch $out"
else
  throw (builtins.toJSON results)
