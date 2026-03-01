# README.md + DESIGN.md Security Review (Nation-State Threat Model)

Scope: documentation-only review of `README.md` and `DESIGN.md`.

## Pass 1: Correctness / Internal Consistency

1. **Development mode wording: "quorum" is wrong term.**
   - In development mode, failure to reach Rekor is an **attestation verification/liveness** failure, not contract quorum failure.
   - **Fix:** replace development mode "quorum cannot be reached" phrasing with "required attestation evidence is unavailable; verification fails closed."

2. **Production key custody conflicts with threat model.**
   - Threat section correctly prefers HSM-backed keys, but Production key management still says CI secret stores.
   - **Proposed fix (normative):**
     - Production: builder signing keys **MUST** be non-exportable (HSM/Managed HSM/KMS-HSM class).
     - CI secret-store raw private keys are **NOT ALLOWED** for Production.
     - If temporarily unavoidable, label as development-only exception with explicit risk acceptance and expiry.

3. **"No software-only solution" caveat is buried.**
   - This caveat should appear near architecture/trust intro, not only in deep threat narrative.
   - **Fix:** add a short, explicit "Guarantee boundary" callout near top of DESIGN.

## Pass 2: Feasibility / Operability

1. **Genesis ceremony is secure but operationally brittle.**
   - M-of-M + multi-sig finalization is right for trust anchor, but needs failure handling.
   - **Action:** add break-glass and recovery runbooks (lost key, unavailable builder, compromised signer).

2. **OCI referrer dependence needs durability guidance.**
   - Registry behavior on referrers/retention is inconsistent.
   - **Action:** document supported registries, retention requirements, and provenance backup/replication policy.

## Pass 3: Nation-State Red-Team Lens

1. **Common-mode software risk needs explicit controls.**
   - Independence by jurisdiction/org is insufficient if builders share same runtime stack.
   - **Action:** require stack diversity across N builders (OS family, kernel line, container runtime, signer backend).

2. **TOCTOU/source retrieval requirements need to be explicit.**
   - Inputs are bound in attestations, but pre-build fetch procedure is not spelled out.
   - **Fix:** require immutable commit checkout and strict digest validation before build begins.

3. **Verifier policy is underspecified.**
   - `nix show-config` is captured, but reject conditions are not normative.
   - **Fix:** add MUST-fail verifier rules (e.g., non-empty substituters in Production, identity mismatch, missing required predicates/fields).

4. **Metadata exposure is acknowledged; controls should be concrete.**
   - Public-chain and CI metadata observability is intrinsic.
   - **Action:** add metadata-minimization checklist (run naming, timestamp granularity where possible, artifact annotation discipline).

## Pass 4: Grokability / Documentation UX

1. **README should sell; DESIGN should stay technical.**
   - README should be concise, adoption-oriented, and outcome-focused.
   - DESIGN should remain precise and implementation/security normative.

2. **Development mode vs Production comparison should be centralized.**
   - Add one compact matrix near top of DESIGN: identity root, quorum semantics, liveness dependency, key custody, cache policy, failure mode.

3. **Terminology and operator usability can be tighter.**
   - Add glossary for "release" / "seed release" / project release.
   - Add short "Operator Checklist" mapping controls to required settings.

## Priority Actions

<ol>
  <li>Correct development mode language: replace "quorum" wording with attestation verification failure semantics.</li>
  <li>Make HSM/non-exportable signing keys a Production <strong>MUST</strong>; forbid raw CI-stored private keys in Production.</li>
  <li>Add explicit source-fetch integrity procedure (immutable commit checkout + digest verification pre-build).</li>
  <li>Publish normative verifier <strong>MUST-fail</strong> rules for in-toto predicates and `nix show-config` constraints.</li>
  <li>Document registry/referrer durability requirements and provenance replication strategy.</li>
  <li>Add genesis/revocation/key-loss incident runbooks.</li>
  <li>Add builder stack-diversity requirements to reduce common-mode compromise risk.</li>
  <li>Restructure docs: README as value proposition, DESIGN as pure technical spec + operator checklist.</li>
</ol>
