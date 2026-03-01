# Nix Seed

Fast Nix builds on non-native ephemeral CI runners.

Happy-path (application source changes): **build starts in seconds**.

Nix Seed bypasses the `/nix/store` realization bottleneck by packaging both Nix
and the dependency closure for all the flake's outputs (apps, checks, devShells,
and packages) as content-addressed OCI layers.

Post build, the builder generates and signs an SLSA provenance attestation.

<!-- AGENT: what about SBOM? -->

The trust model is:

1. **Level 1 (single builder, Rekor log):** Weakest guarantee. Cost: free.
1. **Level 2 (N-of-M builder quorum, Rekor log):** A *master builder*
   executes the promotion step when the configured builder quorum is reached.
   Better, but the Rekor public-good instance has no SLA (so downtime may block
   quorum) and is subject to US legal capture. Both the master builder and the
   Rekor instance are critical attack surfaces. Cost: free.
1. **Level 3 (N-of-M builder quorum, L2 Smart Contract):** Anchors release
   builds to an L2 Smart Contract. There are **no central actors**. The ledger
   is immutable. Strongest guarantee. Cost (assuming 3 builders across 4
   systems): 0.00081 to 0.00296 ETH ($2.43 to $8.88 at ETH = $3,000). <!--
   AGENT: validate cost range -->

> Breaking flow state to watch CI download and extract the dependency set,
> again: $$$.
>
> Compute bill for same: $$$.
>
> A build guaranteed by hard math: Priceless.

See [Design](./DESIGN.md) for architectural breakdown and threat model.

> Woosh... Wondering any of that even meant? See [Glossary](./GLOSSARY.md).

## Quickstart

> [!NOTE]
>
> This quickstart demonstrates a minimal Level 1 example for evaluation. It
> prioritizes speed over trust.

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
          # placeholder
          default = pkgs.hello;
          # seed is passed flake self, and realizes the inputs of all flake
          # outputs
          seed = inputs.nix-seed.lib.mkSeed {
            inherit pkgs;
            inherit (inputs) self;
          };
        }
      );
  };
}
```

Add a workflow to orchestrate the seed generation:

> [!WARNING]
>
> Seed build requires `packages: write` and `id-token: write` permissions. Never
> trigger seed generation with write tokens on untrusted pull requests to
> prevent privilege escalation and/or namespace poisoning.

`.github/worflows/seed.yaml`:

```yaml
name: seed
on:
  push:
    branches:
      - master
    paths:
      # these are baseline, if there is any other source of truth for
      # dependencies, for example a `pyproject.toml` consumed by
      # `pyproject-nix`, they MUST be included here. The build workflow MUST
      # have a matching list in its `paths-ignore`.
      - flake.nix
      - flake.lock
  workflow_dispatch:
jobs:
  seed:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      packages: write
    steps:
      - uses: actions/checkout@v6
      - uses: 0compute/nix-seed@v1/seed
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}



```

`.github/worflows/build.yaml`:

```yaml
on:
  push:
    branches:
      - master
    paths-ignore:
      - flake.nix
      - flake.lock
  workflow_run:
    workflows:
      - seed
    types:
      - completed
jobs:
  build:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    strategy:
      matrix:
        os:
          - macos-15
          - macos-15-intel
          - ubuntu-22.04
          - ubuntu-22.04-arm
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v6
      - uses: 0compute/nix-seed@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          # the outputs list as specified below is the default, shown here for
          # illustrative purposes - override if you need something different
          # outputs are built in parallel (property of nix)
          #
          # output refs resolve with system where you would expect i.e.
          # packages.default refs packages.x86_64-linux.default if the builder 
          # is of that system
          outputs:
            - apps.default
            - checks.default
            - devShells.default
            - packages.default
          # cachix is optional, not necessary if your only build output is an #
          image that gets pushed to a registry; otherwise extremely useful as a
          # project-specific cache so contributors can get set fast.
          cachix_cache: <name>
          cachix_auth_token: ${{ secrets.CACHIX_AUTH_TOKEN }}

```

## Level 2

Level 2 anchors releases on Rekor using an N-of-M builder quorum. No single
builder, organisation, or jurisdiction, can unilaterally forge a release (except
for `.gov`). See [Design: Level 2](./DESIGN.md#level-2) for full model.

## Level 3

Level 3 anchors releases on Ethereum L2 using an N-of-M builder quorum.
No single builder, organisation, or jurisdiction can unilaterally forge a
release. See [Design: Production](./DESIGN.md#production-todo) for the full
trust model.

> [!WARNING]
>
> The [design doc](./DESIGN.md) contains critical security information.
>
> Read it. Twice. Or, get pwned.

**Setup sequence:**

1. **Configure builders** - define the builder set in the flake's `seedCfg`
   output with M >= 3. Builders **MUST** be jurisdictionally, organizationally,
   and technically independent for the quorum to be meaningful.
2. **Execute genesis** - all M builders independently build the seed from source
   with substitution disabled, submit unanimous attestations, and co-sign the
   genesis transaction. See [Design: Genesis](./DESIGN.md#genesis).
3. **Key management** - builder signing keys in HSM is preferred if costs permit.
   Configure governance multi-sig for key rotation and revocation.

See [Design: Threat Actors](./DESIGN.md#threat-actors) for guidance on selecting
independent builder operators.
