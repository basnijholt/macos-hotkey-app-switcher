#!/usr/bin/env bash
# Build a universal (arm64 + x86_64) binary at build/macos-hotkey-app-switcher. Needs the Xcode command line tools.
set -euo pipefail
cd "$(dirname "$0")/.."

for arch in arm64 x86_64; do
  mkdir -p "build/$arch"
  swiftc -O -module-name MacosHotkeyAppSwitcher -target "$arch-apple-macos13" \
    -framework AppKit -framework Carbon macos-hotkey-app-switcher.swift -o "build/$arch/macos-hotkey-app-switcher"
done
lipo -create build/arm64/macos-hotkey-app-switcher build/x86_64/macos-hotkey-app-switcher -output build/macos-hotkey-app-switcher
lipo -info build/macos-hotkey-app-switcher
