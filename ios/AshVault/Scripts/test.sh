#!/usr/bin/env bash
# Local test runner — always uses the dedicated AshVault simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="$("$ROOT/Scripts/ci/ensure-simulator.sh")"
SCHEME="${1:-AshVault}"
if (($# > 0)); then shift; fi

echo "AshVault simulator: $DESTINATION"
echo "Scheme: $SCHEME"

ARGS=(
  test
  -project AshVault.xcodeproj
  -scheme "$SCHEME"
  -destination "$DESTINATION"
)

if (($# > 0)); then
  ARGS+=("$@")
fi

xcodebuild "${ARGS[@]}"
