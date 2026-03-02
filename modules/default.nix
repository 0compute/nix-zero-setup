{ inputs, inputs', ... }:
{

  imports = [
    ./apps.nix
    ./checks.nix
    ./devshells.nix
    ./docs.nix
    # TODO: https://flake.parts/options/files.html
    # ./files.nix
    ./githubactions.nix
    ./hooks.nix
    # ./nixunit.nix
    ./packages.nix
    ./seedcfg.nix
    ./builders.nix
  ];

  systems = import inputs.systems;

  flake.lib.mkSeed = import ../mkseed.nix {
    inherit (inputs') nix-attest nix2container;
  };

  flake.lib.mkBuild = import ../mkbuild.nix;

}
