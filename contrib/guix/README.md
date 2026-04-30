# Cyberyen Guix Reproducible Build System

This directory contains the Guix-based reproducible build system for Cyberyen Core.

**Status**: Work in progress (feature/guix-build-system branch)

## Quick Start (Local Test)

```bash
# 1. Enter Guix environment
guix shell --pure -m manifest.scm -- bash

# 2. Run the build
./contrib/guix/guix-build.sh
```

## Supported Targets

- `x86_64-unknown-linux-gnu` (Linux)
- `x86_64-w64-mingw32` (Windows)
- `x86_64-apple-darwin` (macOS)

## How to Build

1. Make sure Guix is installed and running (`guix-daemon`).
2. Run:
   ```bash
   contrib/guix/guix-build.sh
   ```

## Important Notes for Cyberyen

- Scrypt hashing is built-in.
- MWEB (MimbleWimble Extension Blocks) is enabled by default.
- Wallet and GUI are enabled by default.
- Berkeley DB is disabled by default (uses SQLite).

## Future Plans

- Full GitHub Actions integration (CI + automatic releases)
- Deterministic binaries for all 3 platforms
- Unsigned releases with clear user instructions

For questions or issues — open an issue in the main repository.
