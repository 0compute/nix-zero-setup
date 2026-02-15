{

  description = "Fast Nix builds for GitHub actions";

  nixConfig = {
    extra-substituters = [ "https://nix-fast-build-action.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-fast-build-action.cachix.org-1:lNgsI3Nea9ut1dJDTlks9AHBRmBI+fj9gIkTYHGtAtE="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs:
    (inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let

        pkgs = inputs.nixpkgs.legacyPackages.${system};
        lib = import ./lib.nix pkgs;

        nixFastBuildContainer = lib.mkBuildContainer {
          name = "nix-fast-build";
          tag = with inputs; self.rev or self.dirtyRev or null;
        };

      in
      {

        packages = {
          inherit nixFastBuildContainer;
          default = nixFastBuildContainer;
          example = lib.mkBuildContainer pkgs.spotify;
        };

        apps =
          {

            default = {
              type = "app";
              program = lib.getExe (
                let
                  inherit (nixFastBuildContainer) imageName imageTag;
                in
                pkgs.writeShellApplication {
                  name = "self-build";
                  text = ''
                    nix() {
                      if command -v nom >/dev/null; then
                        nom "$@"
                      else
                        command nix "$@"
                      fi
                    }
                    nix build .#nixFastBuildContainer
                    docker load < result
                    docker tag "${imageName}:${imageTag}" "${imageName}:latest"
                  '';
                }
              );
            };

            github-action = {
              type = "app";
              program = lib.getExe (
                pkgs.writeShellApplication {
                  name = "github-action";
                  text = ''
                    nix build "$@"
                    docker load < result
                    name="ghcr.io/$GITHUB_REPOSITORY"
                    for tag in "$GITHUB_SHA" "$(git describe --tags --always)" latest; do
                      docker tag "''${GITHUB_REPOSITORY##*/}:$GITHUB_SHA" "$name:$tag"
                    done
                    docker login ghcr.io \
                      --username "$GITHUB_ACTOR" \
                      --password-stdin <<< "$GITHUB_TOKEN"
                    docker push --all-tags "$name"
                  '';
                }
              );
            };

          };

      }
    ));

}
