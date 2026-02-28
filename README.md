# Nix Seed

Nix Seed provides OCI seed images for Nix-built projects, packaging their
dependency closure as content-addressed OCI layers to eliminate per-job
reconstruction of `/nix/store`.

The design goal is time-to-build. Supply-chain trust properties are a free
result. See [design](./DESIGN.md) for architecture, performance model, trust
modes, and threat model.

## Why?

In environments without a pre-populated `/nix/store`, the entire dependency
closure must be realized before a build can begin. This setup tax often
dominates total job time.

Build time does not change. Setup time does. Source must always be fetched
(typically via shallow clone).

Traditional CI setup scales with total dependency size. Seeded CI setup scales
with dependency change since the last seed.

When only application code changes, the previous seed is reused and
time-to-build is near-instant. When the input graph changes, or when no seed
exists yet, the seed is built before application build.

## Quickstart

> [!NOTE] This quickstart demonstrates a minimal, single-builder (1-of-1)
> example for evaluation. This completely bypasses the trust model. For
> production, see the documentation on orchestrating an N-of-M quorum.

Add `nix-seed` to your flake and expose a `seed` attribute:

```nix
{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-seed = {
      url = "github:0compute/nix-seed";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs: {
    packages =
      inputs.nixpkgs.lib.genAttrs (import inputs.systems) (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          # placeholder: replace with your derivation
          default = pkgs.hello;
          seed = inputs.nix-seed.lib.mkSeed {
            inherit pkgs;
            inherit (inputs) self;
          };
        }
      );
  };

}
```

### GitHub Actions

Add a workflow:

> [!WARNING] This job runs with `packages: write` and `id-token: write`
> permissions. Never trigger seed generation with write tokens on untrusted pull
> requests to prevent privilege escalation and/or namespace poisoning.

```yaml
on:
  push:
    branches:
      - master

jobs:
  seed:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      packages: write
    steps:
      - uses: actions/checkout@v6
      - uses: 0compute/nix-seed@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
  build:
    runs-on: ubuntu-latest
    needs: seed
    steps:
      - uses: actions/checkout@v6
      - uses: 0compute/nix-seed@v1/actions/build
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
