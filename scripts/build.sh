#!/usr/bin/env bash
# Build a universal (arm64 + x86_64) binary at build/app-hotkeys. Needs the Xcode command line tools.
set -euo pipefail
cd "$(dirname "$0")/.."

for arch in arm64 x86_64; do
  mkdir -p "build/$arch"
  swiftc -O -module-name AppHotkeys -target "$arch-apple-macos13" \
    -framework AppKit -framework Carbon app-hotkeys.swift -o "build/$arch/app-hotkeys"
done
lipo -create build/arm64/app-hotkeys build/x86_64/app-hotkeys -output build/app-hotkeys
lipo -info build/app-hotkeys
