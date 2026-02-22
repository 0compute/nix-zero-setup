# Nix Seed

Hermetic. Deterministic. Cacheable. Fast.

## Overview

`Nix Seed` provides OCI build containers with the flake input graph baked in.
Extreme cacheability is a core principle.

- **Build seeds:** hermetic, full-featured; include base, library, apps, checks,
  devShells, overlays.
- **Runtime seeds:** hermetic and slim; include base, library, and apps.
  Optional musl variant is available for smaller runtimes. Containers are e

Nix Seed targets fast rebuilds when cached without compromising hermeticity or
reproducibility Nix in the container is configured with `substitutes = false` so
builds do not require network.

pins all inputs for deterministic, cacheable builds, so rebuilds are quick

when layers are unchanged.

![XKCD Compiling](https://imgs.xkcd.com/comics/compiling.png)

> > Not any more fuckers. Work Harder.

**By using pre-baked OCI layers, .** Hermetic builds isolate from host and
network influences; reproducible builds aim for identical outputs when inputs
and tooling are pinned.

**Note:** Base layers use a minimized Nixpkgs derivation. Size depends on the
package set but remains fully Nix-native.

## Quick Start

Build the default seed and load it into Docker:

```sh
nix build .#seed
docker load < result
```

List loaded images:

```sh
docker image list
```

### Comparison with Nix Community / GH Actions Caches

| Feature | Nix Seed (pre-baked layers) | Standard caches | | --- | --- | --- |
| Hermetic build | ✅ fully isolated | ⚠ may fetch missing paths | | Reproducible
| ✅ pinned inputs/tools | ⚠ host/tool differences | | Incremental rebuilds | ✅
only changed layers | ⚠ larger rebuild surface | | Multi-layer reuse | ✅ base,
libs, apps, checks, devShells, overlays | ❌ flat cache | | Cache keys | ✅ flake
input hash per layer | ⚠ ad hoc or per-derivation | | Network dependency | ❌
offline possible | ⚠ remote caches; bandwidth + untar CPU | | Developer speed |
✅ near-instant when cached | ⚠ slower; more network and CPU |

**Summary:** Nix Seed turns the pinned dependency graph into reusable OCI
layers, not single store paths. That yields faster, hermetic, reproducible
builds, without the setup tax of repeatedly populating per-run Nix caches in
typical GitHub Actions flows.

## Layer -> OCI -> Cache Diagram

Split output/layer to OCI layer to cache key mapping:

| Output or layer | OCI layer | Cache key | | --- | --- | --- | | base | Layer 1
| hash(base + inputs) | | library | Layer 2 | hash(library + inputs) | | apps |
Layer 3 | hash(apps + scripts) | | checks | Layer 4 | hash(tests + deps) | |
devShells | Layer 5 | hash(dev tools + notebooks) | | overlays | Layer 6 |
hash(overlays) |

- Runtime seed: base + library + apps.
- Build seed: all layers for hermetic, cacheable builds.

## Flake Schema Layered Nix OCI Seeds

Nix Seed supports split outputs per derivation to implement layers
automatically. Users can define dependencies in standard layer names, and Nix
Seed will produce hermetic, cacheable layers.

Usage outline:

- Define split outputs for `base`, `library`, `apps`, optional `checks`,
  `devShells`, `overlays`.
- Keep each output scoped to its layer dependencies.
- Runtime images include base + library + apps; build images include all layers.

### Standard Layer Helper Function (Embedded)

```nix
{ pkgs }:

let
  standardLayers = {
    base = [ pkgs.python pkgs.gcc pkgs.coreutils ];
    library = [ pkgs.numpy pkgs.pandas pkgs.matplotlib ];
    apps = [ ./my-script ./my-model ];
    checks = [ ./tests ];
    devShells = [ pkgs.jupyter pkgs.streamlit ];
    overlays = [ ./my-overlay ];
  };

in
  pkgs.stdenv.mkDerivation {
    name = "nix-seed-standard-layers";
    outputs = builtins.attrNames standardLayers;

    buildCommand = ''
      for layer in ${builtins.concatStringsSep " " (builtins.attrNames standardLayers)}; do
        mkdir -p $out/$layer
        cp -r ${standardLayers.$layer}/* $out/$layer/
      done
    '';
  }
```

Users can override or extend standard layers as needed. Each split output maps
to an OCI layer. Runtime seeds include base + library + apps; build seeds
include all layers. Runtime excludes: checks, devShells, overlays.

## Layered Seed Architecture

- **Base layer:** OS, compilers, Python runtime (minimal Nixpkgs).
- **Library layer:** libraries, numerical and ML packages.
- **Apps layer:** Python scripts, AI pipelines, models.
- **Checks layer:** unit tests, validation scripts.
- **DevShells layer:** developer tools, Jupyter, Streamlit (build-only).
- **Overlays layer:** patches, version overrides (build-only).

## Runtime vs Build Layer Table

| Layer | Runtime seed | Build seed | | --- | --- | --- | | base | ✅ | ✅ | |
library | ✅ | ✅ | | apps | ✅ | ✅ | | checks | ❌ | ✅ | | devShells | ❌ | ✅ | |
overlays | ❌ | ✅ |

Runtime includes only base + library + apps. Optional musl runtime is available
for smaller images. Build seed includes all inputs for all layers to preserve
hermeticity and caching.

Expected runtime sizes:

- Small scripts: ~1-10 MB.
- Minimal base: ~15-25 MB.
- AI stack runtime: ~500-900 MB (CPU), GPU variant ~2-3 GB compressed.

## GitHub Actions Integration

Nix Seed can be used in [GitHub Actions](https://docs.github.com/actions) to
build and publish images with pinned inputs and cacheable layers.

- Run builds with `--option substitute false` to force local derivation builds.
- If your workflow uses Node-based actions, ensure Node is available in the
  build image at a predictable path.
- Setting `github_token` triggers load, tag, and push in one publish step. Omit
  it to build only. Add extra tags via `tags`. Use `registry` to push somewhere
  other than ghcr.io. Use `tag_latest: true` only when publishing the manifest
  after all systems finish. `seed_attr` defaults to `.#seed`. Seeds default to
  `substitutes = false`; set `substitutes = true` in `mkseed.nix` if you want to
  allow binary cache use inside the seed.

Example workflow using the local composite action:

```yaml
name: build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: ./
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          seed_attr: .#seed
```

Example workflow using a published action (replace the ref):

```yaml
name: build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: your-org/nix-seed@v0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          seed_attr: .#seed
```

## Expected Time-to-Build

| Scenario | Approx. time | Notes | | --- | --- | --- | | Fully cached | ~0-5
sec | Eval + layer verification | | Project layer invalidated | 10-60 sec |
Top-level package rebuild | | Library layer invalidated | 1-5 min | Dependency
rebuild | | Toolchain/base invalidated | 5-20+ min | Full graph rebuild |

Incremental rebuilds only invalidate layers whose inputs changed. Runtime seeds
are hermetic and slim; build seeds include all inputs for all layers.

## Multi-Target / Multi-Arch

- Cross-compilation handled hermetically.
- Supports x86_64 and ARM64, Linux and Darwin targets.
- Darwin builds run inside Linux OCI seeds on macOS hosts.
- SDKs for macOS are build-time-only; where required, only the flake hash is
  used.
- No emulation required for CPU-only builds.
- Optional musl runtimes available for smaller images.
- Designed for developer speed: only changed layers rebuild.
- Nix `system` is the platform triple used by flake outputs (for example,
  `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`). OCI manifests use
  `os/arch` (`linux/amd64`, `linux/arm64`, `darwin/arm64`); pick the matching
  Nix `system` when building per-arch images and apply `latest` only when
  tagging the manifest list.

### Attestation

TODO: flesh out

Containers (seeds) embed OCI Attestations as:

```json
{
  "flakeHash": "sha256-flake-and-inputs",
  "layerHashes": {
    "base": "sha256",
    "library": "sha256",
    "apps": "sha256",
    "checks": "sha256",
    "devShells": "sha256",
    "overlays": "sha256"
  },
  "seedDigest": "sha256",
  "signature": "gpg-or-slsa",
  "builtBy": "builder-identity",
  "timestamp": "ISO8601"
}
```

- `flakeHash`: inputs match the declared pinned flake.
- `layerHashes`: each split output layer is unmodified.
- `seedDigest`: final OCI image digest.
- `signature`: optional GPG or SLSA signature for authenticity.

TODO: SBOM

## Trust No Fucker

> "The code was clean, the build hermetic, but the compiler was pwned.
>
> Just because you're paranoid doesn't mean they aren't out to fuck you."
> — **Apologies to Joseph Heller, *Catch-22* (1961)**

Even with attested, hermetic, and deterministic builds, attacks like Ken Thompson's
[Trusting Trust](https://dl.acm.org/doi/10.1145/358198.358210) remain a concern. A
rigged build environment can undetectably inject code during compilation.

Assume that any build environment can and will be compromised.

### Transparency

Use Sigstore (cosign) to issue In-Toto statements. Every build records its {commit,
system, narHash} in a public ledger (Rekor).

### Immutable Promotion (EVM L2)

Promotion of a build is not a manual flag but a cryptographic event. A quorum ($n$ of
$m$) of independent builders must agree on the narHash before the mapping is anchored
into a smart contract on an L2 blockchain.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
* @title TNFArtifactRegistry
* @dev Anchors a mapping of commit+system to a narHash once quorum is reached.
*/
contract TNFArtifactRegistry {
// commitHash + system (e.g., x86_64-linux) -> narHash
mapping(bytes32 => string) public promotedBuilds;

// Authorization: Only the Watchdog/Multisig can anchor a promotion
address public watchdog;

event BuildPromoted(bytes32 indexed buildKey, string narHash);

constructor(address _watchdog) {
    watchdog = _watchdog;
}

/**
* @notice Records the narHash once the off-chain Watchdog verifies n-of-m Rekor attestations.
* @param _commit The git commit hash
* @param _system The Nix system tuple
* @param _narHash The resulting Nix Archive hash
*/
function anchorPromotion(bytes32 _commit, string calldata _system, string calldata _narHash) external {
    require(msg.sender == watchdog, "TNF: Unauthorized caller");
    
    bytes32 buildKey = keccak256(abi.encodePacked(_commit, _system));
    
    // Ensure immutability: once anchored, it cannot be "re-pwned"
    require(bytes(promotedBuilds[buildKey]).length == 0, "TNF: Build already anchored");

    promotedBuilds[buildKey] = _narHash;
    emit BuildPromoted(buildKey, _narHash);
}
}
```

Gas economics matter: because every promotion writes to an L2 registry, prefer batching
promotions under a Merkle root and reuse the cheapest finality window (e.g., optimistic
rollups). Estimate ~50k gas per `anchorPromotion` call, so at 0.5 gwei (~0.0000000005
ETH) the per-hash cost is under $0.03 on current rollups; adjust the gas limit if the L2
gas price spikes to keep per-hash gas cost predictable and low.

### Endgame

With [nixpkgs full-source
  bootstrap](https://discourse.nixos.org/t/a-full-source-bootstrap-for-nixos/)
this is endgame for supply chain security.

## Legal Compliance

Lawyers fuck you twice as hard.

Nix Seed is legally unimpeachable. Upstream license terms for non-redistributable SDKs
are fully respected, leaving zero surface area for litigation.
