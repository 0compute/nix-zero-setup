{ pkgs, mkSeed }:
pkgs.testers.runNixOSTest {

  name = "func";

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation = {
        diskSize = 4096;
        memorySize = 4096;
        podman.enable = true;
      };
      environment.systemPackages = [ pkgs.git ];
    };

  testScript =
    let
      img = mkSeed {
        inherit pkgs;
        name = "nix-seed";
      };
      tag = with img; "${imageName}:${imageTag}";
      mkseed = pkgs.writeText "mkseed.nix" (builtins.readFile ./../mkseed.nix);
      testflake = pkgs.writeText "flake.nix" (
        builtins.readFile ./functional-flake.nix
      );
    in
    builtins.readFile (
      pkgs.replaceVars ./functional.py {
        inherit
          img
          tag
          mkseed
          testflake
          ;
      }
    );

}
