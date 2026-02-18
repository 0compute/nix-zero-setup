# ruff: noqa
# from typing import TYPE_CHECKING
#
# if TYPE_CHECKING:
#     from nixos_test_driver.driver import Machine
#
#     machine: Machine = None

machine.wait_for_unit("docker.service")
machine.succeed("docker load < @img@")

# verify Nix is available and functional in the container
machine.succeed("docker run --rm --entrypoint nix @tag@ --version")

# create a minimal Nix project to build inside the container
# we use builtins.derivation to avoid stdenv/nixpkgs dependencies
machine.succeed("mkdir -p /tmp/test-project")
machine.copy_from_host("@mkbuildcontainer@", "/tmp/test-project/mkbuildcontainer.nix")

flake_content = r"""
{
outputs = _: {
    packages.x86_64-linux.default =
    let
        # minimal mock pkgs with inline lib implementation
        pkgs = {
        lib = {
            head = list: builtins.elemAt list 0;
            concatMap = f: list: builtins.concatLists (map f list);
            mapAttrsToList = f: attrs:
            map (name: f name attrs.${name}) (builtins.attrNames attrs);
            removeAttrs = attrs: names: builtins.removeAttrs attrs names;
            concatStringsSep = sep: list: builtins.concatStringsSep sep list;
            getExe = pkg: "${pkg}/bin/nix";
        };
        nixVersions.latest = { outPath = "/nix"; pname = "nix"; };
        nix = { outPath = "/bin/nix"; };
        coreutils = { outPath = "/bin"; };
        bashInteractive = { outPath = "/bin/bash"; };
        git = { outPath = "/bin/git"; };
        cacert = { outPath = "/etc/ssl/certs"; };
        dockerTools.buildLayeredImageWithNixDb = args:
            derivation {
            name = args.name;
            builder = "/bin/bash";
            args = [ "-c" "touch $out" ];
            system = "x86_64-linux";
            PATH = "/bin";
            };
        };
        mkBuildContainer = import ./mkbuildcontainer.nix;
    in mkBuildContainer {
        inherit pkgs;
        name = "test-container";
        inputsFrom = [ pkgs.coreutils ];
    };
};
}
"""
machine.succeed(f"echo '{flake_content}' > /tmp/test-project/flake.nix")
# initialize git so Nix sees the files in the flake
machine.succeed("cd /tmp/test-project && git init && git add .")

# run nix eval inside the container to verify flake evaluation works
machine.succeed(
    " ".join(
        (
            "docker run",
            "--rm",
            "-v /tmp/test-project:/src",
            "-w /src",
            "@tag@",
            "eval",
            "--impure",
            "--accept-flake-config",
            "--extra-experimental-features 'nix-command flakes'",
            ".#default.name",
        )
    )
)
