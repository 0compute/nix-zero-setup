# e2e test: build all example projects dynamically
{ pkgs, mkBuildContainer, flake-utils, pyproject-nix }:
let
  inherit (pkgs) lib system;

  # mock nix-zero-setup input for examples
  nixZeroSetup = {
    lib = { inherit mkBuildContainer; };
  };

  # mock nixpkgs input
  nixpkgs = {
    legacyPackages.${system} = pkgs;
  };

  # all available inputs for examples
  availableInputs = {
    self = { };
    inherit nixpkgs flake-utils pyproject-nix;
    nix-zero-setup = nixZeroSetup;
  };

  examplesDir = ../examples;

  # discover all example directories
  exampleNames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir examplesDir)
  );

  # import and build each example
  buildExample = name:
    let
      flake = import (examplesDir + "/${name}/flake.nix");
      outputs = flake.outputs availableInputs;
    in
    outputs.packages.${system}.nix-build-container;

  containers = map (name: {
    inherit name;
    container = buildExample name;
  }) exampleNames;

in
pkgs.runCommand "e2e-examples"
  {
    passAsFile = [ "containerList" ];
    containerList = lib.concatMapStringsSep "\n" (c: "${c.name}=${c.container}") containers;
  }
  ''
    echo "Verifying example containers..."
    while IFS='=' read -r name path; do
      test -f "$path" || { echo "FAIL: $name ($path)"; exit 1; }
      echo "OK: $name"
    done < "$containerListPath"
    mkdir -p $out
    echo "All e2e checks passed" > $out/result
  ''
