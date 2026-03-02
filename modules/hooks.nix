{ inputs, ... }:
{

  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    { lib, pkgs, ... }:
    {

      pre-commit.settings.hooks =
        lib.recursiveUpdate
          (
            (lib.genAttrs
              [
                # TODO: verify scripts/lint/lint.sh

                # gha
                "action-validator"
                "actionlint"
                # pre-commit
                "check-added-large-files"
                "check-merge-conflicts"
                "check-shebang-scripts-are-executable"
                # nix
                "deadnix"
                "flake-checker"
                "statix"
                # python
                "ruff"
              ]
              (_name: {
                enable = true;
              })
            )
            // (lib.listToAttrs (
              map
                (drv: {
                  inherit (drv) name;
                  value = {
                    enable = true;
                    entry = lib.getExe drv;
                  };
                })
                (
                  with pkgs;
                  [
                    codespell
                    ty
                  ]
                )
            ))
          )
          {

            # default is 100, is not a hard limit - this makes it in effect 95
            nixfmt.settings.width = 77;

            ty.entry = "${lib.getExe pkgs.ty} check";

          };

    };

}
