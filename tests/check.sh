#!/usr/bin/env bash
# Smoke-test a built binary: tests/check.sh path/to/app-hotkeys
set -euo pipefail
bin=$(realpath "${1:?usage: tests/check.sh <app-hotkeys binary>}")
cd "$(dirname "$0")/.."

echo "== $bin --version"
version=$("$bin" --version)
echo "$version"
[[ $version =~ ^app-hotkeys\ [0-9]+\.[0-9]+\.[0-9]+$ ]]

echo "== the example config passes --check"
"$bin" --check examples/hotkeys.conf

echo "== a broken config fails --check with exit 1 and names each bad line"
err=$(mktemp)
code=0
"$bin" --check tests/broken.conf 2> "$err" || code=$?
cat "$err"
[ "$code" -eq 1 ] || { echo "expected exit 1, got $code"; exit 1; }
grep -q "line 3: unknown modifier 'bogus'" "$err"
grep -q "line 4: ctrl+alt+shift+s is the same chord as line 2" "$err"

echo "== an unknown flag exits 2"
code=0
"$bin" --bogus 2> /dev/null || code=$?
[ "$code" -eq 2 ] || { echo "expected exit 2, got $code"; exit 1; }

echo "all checks passed"
