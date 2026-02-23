# Nix Seed

Nix Seed provides near-instant, cryptographically attestable CI builds.

## Mission

### Problem: Purity Ain't Free

Nix purity guarantees come with a tax in non-native ephemeral environments: every
derivation must be fetched, materialized, and verified before it can be trusted. Missing
inputs force CI runs to substitute from binary caches or rebuild from source, which
delays the job, fragments caches, and burns network/CPU. The more dependencies a project
has, the more often CI stalls on the download/unpack/verify loop instead of the actual
build.

For GitHub CI, [Cache Nix Action](https://github.com/nix-community/cache-nix-action) and
[Nix Magic Cache](https://github.com/DeterminateSystems/magic-nix-cache-action) reduce
the need to reach outside of GitHub's backbone, but are still largely network and CPU
bound.

<!-- TODO: real numbers -->

Time-to-build with no input changes: >60s

### Solution: Seed Containers

Nix Seed provides layered OCI build containers with the flake inputs closure baked in.
Unchanged layers are reused across builds, which yields extreme cacheability without
relaxing hermeticity. A commit that changes app code without modifying inputs, which
will be most of them, starts its CI build near instantly because all of the other layers
are already cached. Publishing to GHCR keeps images close to GitHub-hosted runners,
reducing pull time and cold-start overhead.

<!-- TODO: real numbers -->

Time-to-build with no input changes: \<5s

#### Layer breakdown

##### Seed container

- **base**: libc, CA certs, readonly shell foundation shared by every image.
- **toolchain**: nix, glibc, libstdc++, compilers, debug tools.
- **build/input layers**:
  - **packages**: foundational derivations at the bottom of the stack.
  - **apps**: depends on packages so comes next.
  - **checks**: verifies the above outputs.
  - **devShells**: developer tooling after the main outputs.
- **container**: container glue (entrypoint, env configuration).

##### Run container

- **base**: shared
- **lib**: app runtime dependencies
- **app**: app
- **container**: container glue (entrypoint, env configuration).

### Problem: Trusting Trust

> The code was clean, the build hermetic, but the compiler was pwned.
>
> Just because you're paranoid doesn't mean they aren't out to fuck you.

**Apologies to Joseph Heller, *Catch-22* (1961)**

Even with hermetic and deterministic builds, attacks like Ken Thompson's
[Trusting Trust](https://dl.acm.org/doi/10.1145/358198.358210) remain a concern. A
rigged build environment that undetectably injects code during compilation is always a
possibility.

### Solution: Trust No Fucker

This is Endgame for supply chain security: every stage explicitly surfaces its inputs
and attestations so downstream users can verify what they run.

#### 1. Bootstrap

Nixpkgs uses full-source bootstrap which starts with a
[human-auditable stage0 hex seed](https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/minimal-bootstrap/stage0-posix/hex0.nix).

#### 2. Provenance

Each container records:

- commit: git commit hash
- system: target environment (in Nix this is `system` i.e. `x86_64-linux` or
  `aarch64-darwin`)
- narHash: represents the absolute derivation of the image
- layerHashes: identify each OCI layer
- builder identity: who performed the build

The builder signs these facts and embeds the signatures as OCI attestation artifacts.
Downstream operators can fetch the attestation with the image metadata to confirm each
input while keeping the provenance layer tied to the cached layers.

Signed statements are also mirrored into [Rekor](https://rekor.dev/) so there is a
public, append-only log of every builder identity plus what it signed. Rekor validates
each attestation, issues a verifiable timestamp, and lets auditors fetch the proof chain
without pulling every image layer — this provides an extra layer of transparency and
tamper-evidence for the provenance facts.

#### 3. Transparency

Supply-side transparency leans on Sigstore (cosign) and Rekor; every build publishes
statements that tie {commit, system, narHash} to the attested image, keeping the ledger
of provenance public and replayable.

#### 4. Immutable promotion

Immutable promotion means anchoring a Merkle root over all systems’ narHashes for a
commit, publishing that root into a public ledger keyed by the commit and the root, and
performing the publish step only after a quorum of Rekor attestations has verified each
member. The outcome is a single globally verifiable, tamper-evident record that anyone
can audit before trusting the build.

## GitHub Actions Integration

Nix Seed provides a [GitHub Action](./action.yml).

- Supports x86_64 and ARM64, Linux and Darwin targets.
- Setting `registry_token` triggers load, tag, and push in one publish step.
- Omit it to build only. Add extra tags via `tags`.
- Use `registry` to push somewhere other than ghcr.io (default: ghcr.io); the action
  logs into that registry automatically using the provided token.
- Use `tags: latest` only when publishing the manifest after all systems finish.
- `seed_attr` defaults to `.#seed`.

Publishing to GHCR keeps images close to GitHub-hosted runners, reducing pull time and
cold-start overhead for cache hits.

### Examples

#### Build and Publish Seed

Workflow file `.github/workflows/build-seed.yaml`:

```yaml
name: Build Seed
on:
  push:
    paths: &paths
      - flake.lock
      - flake.nix
      - .github/workflows/build-seed.yaml
  pull_request:
    paths: *paths
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      - name: Build seed
        uses: 0compute/nix-seed
        with:
          registry_token: ${{ secrets.GITHUB_TOKEN }}
          tags: latest
```

### Build Project with Seed

Workflow file: `.github/workflows/build.yaml`.

```yaml
---
name: Build
on:
  push:
    # MUST: match paths in build-seed.yaml
    paths-ignore: &paths-ignore
      - flake.lock
      - flake.nix
      - .github/workflows/build-seed.yaml
  pull_request:
    paths-ignore: *paths-ignore
  workflow_run:
    workflows:
      - Build Seed
    types:
      - completed
jobs:
  build:
    runs-on: ubuntu-latest
    container: ghcr.io/${{ github.repository }}:latest
    steps:
      - uses: actions/checkout@v6
      - run: nix build
```

## Compliance

Nix Seed is legally unimpeachable. Upstream license terms for non-redistributable SDKs
are fully respected, leaving zero surface area for litigation.

______________________________________________________________________

![XKCD Compiling](https://imgs.xkcd.com/comics/compiling.png "Not any more, fuckers. Get back to work!")
