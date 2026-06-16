#!/usr/bin/env bash
# Lightweight docs parity check for CI artifacts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
OUTPUT="${CI_DOCS_SUMMARY:-documentation-summary.txt}"

required=(
  "README.md"
  "CONTRIBUTING.md"
  "docs/index.html"
  "docs/privacy-policy.html"
  "docs/accessibility.html"
  "docs/support.html"
  "ios/docs/README.md"
  "ios/docs/game-design-spec.md"
)

missing=0
{
  echo "AshVault documentation summary"
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  for path in "${required[@]}"; do
    if [[ -f "${REPO_ROOT}/${path}" ]]; then
      echo "OK  ${path}"
    else
      echo "MISSING  ${path}"
      missing=$((missing + 1))
    fi
  done
  echo ""
  if [[ "$missing" -eq 0 ]]; then
    echo "All required docs present."
  else
    echo "${missing} required doc(s) missing."
    exit 1
  fi
} > "$OUTPUT"
cat "$OUTPUT"
