# Functional test for nix-seed seed image
# Validates that the seed can run Nix commands and evaluate flakes
machine.succeed("podman load < @img@")

# verify Nix is available and functional in the seed
machine.succeed("podman run --rm --entrypoint nix @tag@ --version")

# create a minimal Nix project to build inside the seed
machine.succeed("mkdir -p /tmp/test-project")
machine.copy_from_host("@mkseed@", "/tmp/test-project/mkseed.nix")
machine.copy_from_host("@testflake@", "/tmp/test-project/flake.nix")

# initialize git so Nix sees the files in the flake
machine.succeed("cd /tmp/test-project && git init && git add .")

# run nix eval inside the seed to verify flake evaluation works
machine.succeed(
    " ".join(
        (
            "podman run",
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
