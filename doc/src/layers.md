### Seed

- **base**: libc, CA certs, readonly shell
- **toolchain**: nix, glibc, libstdc++, compilers, debug tools.
- **build/input layers**:
  - **packages**: foundational derivations at the bottom of the stack.
  - **apps**: depends on packages so comes next.
  - **checks**: verifies the above outputs.
  - **devShells**: developer tooling after the main outputs.
- **container**: container glue (entrypoint, env configuration).

### Run

- **base**: shared
- **lib**: app runtime dependencies
- **app**: app
- **container**: container glue (entrypoint, env configuration).
