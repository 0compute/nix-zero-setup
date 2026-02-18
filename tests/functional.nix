{ pkgs, mkBuildContainer }:
pkgs.testers.runNixOSTest {

  name = "func";

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation = {
        docker.enable = true;
        memorySize = 4096;
        diskSize = 4096;
      };
      environment.systemPackages = [ pkgs.git ];
    };

  testScript =
    let
      img = mkBuildContainer {
        inherit pkgs;
        name = "nix-zero-setup";
      };
      tag = with img; "${imageName}:${imageTag}";
      mkbuildcontainer = pkgs.writeText "mkbuildcontainer.nix" (
        builtins.readFile ./../mkbuildcontainer.nix
      );
    in
    builtins.readFile (
      pkgs.replaceVars ./functional.py {
        inherit img tag mkbuildcontainer;
      }
    );

}
