# e2e test: build all example projects
{
  pkgs,
  mkSeed,
  flake-utils,
  pyproject-nix,
}:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;

  # inputs for example flakes
  availableInputs = {
    self = { };
    nixpkgs.legacyPackages.${system} = pkgs;
    nix-seed.lib = { inherit mkSeed; };
    inherit flake-utils pyproject-nix;
  };

  examplesDir = ../examples;

  exampleNames = builtins.attrNames (
    lib.filterAttrs (_name: type: type == "directory") (
      builtins.readDir examplesDir
    )
  );

  buildExample =
    name:
    let
      flake = import (examplesDir + "/${name}/flake.nix");
      outputs = flake.outputs availableInputs;
    in
    outputs.packages.${system}.seed;

  seeds = map (name: {
    inherit name;
    seed = buildExample name;
  }) exampleNames;

in
# AGENT: this is not testing anything - it must do as the header comment says
pkgs.runCommand "examples"
  {
    passAsFile = [ "seedList" ];
    seedList = lib.concatMapStringsSep "\n" (s: "${s.name}=${s.seed}") seeds;
  }
  ''
    echo "Building example seeds..."
    while IFS='=' read -r name path; do
      test -f "$path" || { echo "FAIL: $name ($path)"; exit 1; }
      echo "OK: $name"
    done < "$seedListPath"
    mkdir -p $out
  ''
