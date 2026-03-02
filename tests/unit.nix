{ pkgs, mkSeed }:
let

  results = pkgs.lib.runTests {

    testEnvConfig = {
      expr =
        pkgs.lib.sort (left: right: left < right)
          (mkSeed {
            inherit pkgs;
            nixConf = "extra-features = nix-command";
          }).config.Env;
      expected = pkgs.lib.sort (left: right: left < right) [
        "USER=root"
        "GIT_TEXTDOMAINDIR=${pkgs.git}/share/locale"
        "GIT_INTERNAL_GETTEXT_TEST_FALLBACKS="
        "HOME=/tmp"
        (
          "NIX_CONFIG="
          + "sandbox = false\n"
          + "build-users-group =\n"
          + "substitutes = false\n"
          + "extra-features = nix-command\n"
        )
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        (
          "LD_LIBRARY_PATH=/lib:/lib64:/lib/"
          + pkgs.stdenv.hostPlatform.linuxArch
          + "-linux-gnu"
        )
        (
          "PATH="
          + (toString (
            builtins.path {
              path = ./../bin;
              name = "bin";
            }
          ))
          + ":/bin:/usr/bin:/sbin:/usr/sbin"
        )
      ];
    };

    testDefaultName = {
      expr = (mkSeed { inherit pkgs; }).name;
      expected = "unnamed-seed.tar.gz";
    };

    testCustomName = {
      expr =
        (mkSeed {
          inherit pkgs;
          name = "custom";
        }).name;
      expected = "custom.tar.gz";
    };

    testContentsMerging =
      let
        seed = mkSeed {
          inherit pkgs;
          contents = with pkgs; [ jq ];
        };
      in
      {
        expr = seed.contents;
        expected = seed.corePkgs ++ (with pkgs; [ jq ]);
      };
  };
in
if results == [ ] then
  pkgs.runCommand "unit-tests" { } "touch $out"
else
  throw (builtins.toJSON results)
