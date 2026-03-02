{ inputs, ... }:
{

  perSystem =
    {
      lib,
      pkgs,
      self,
      system,
      ...
    }:
    {

      checks =
        let
          attrs = {
            inherit pkgs;
            inherit (self.lib) mkSeed;
          };
          examples = import ./tests/test_examples.nix { inherit lib inputs system; };
        in
        {

          # nix-unit = import ./tests/unit.nix attrs;

          # nix-functional = import ./tests/functional.nix attrs;

          bats = pkgs.runCommand "bats-tests" { buildInputs = with pkgs; [ bats ]; } ''
            cd ${./.}
            ${lib.getExe pkgs.bats} tests/bin | tee $out
          '';

          # examples = import ./tests/examples.nix (
          #   attrs // { inherit (inputs) flake-utils pyproject-nix; }
          # );

          # examples = pkgs.runCommand "examples" { } ''
          #   cat <<EOF > $out
          #   ${lib.concatLines (
          #     lib.mapAttrsToList (name: seed: "${name}:${seed}") examples
          #   )}
          #   EOF
          # '';

        };

    };

}
