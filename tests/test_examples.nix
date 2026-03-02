{
  lib,
  inputs,
  system,
}:
let

  exampleSeed =
    path:
    let
      seed =
        let
          self = import "${path}/flake.nix";
          outputs = self.outputs (
            inputs
            // {
              inherit self;
              nix-seed = inputs.self;
            }
          );
        in
        outputs.packages.${system}.seed;
    in
    seed;

  exampleDir = ../examples;

in
lib.mapAttrs'
  (
    name: value:
    lib.nameValuePair "example-${name}" (exampleSeed "${exampleDir}/${name}")
  )
  (
    lib.filterAttrs (_name: type: type == "directory") (
      builtins.readDir exampleDir
    )
  )
