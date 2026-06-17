#!/usr/bin/env bash
# Ensures the dedicated AshVault test simulator exists and prints an xcodebuild
# -destination value (platform=iOS Simulator,id=<UDID>).
#
# Usage:
#   ./Scripts/ci/ensure-simulator.sh              # print destination
#   eval "$(./Scripts/ci/ensure-simulator.sh --export)"  # export ASHVAULT_SIM_DESTINATION
#
# Override defaults:
#   ASHVAULT_SIM_NAME=AshVault
#   ASHVAULT_SIM_DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-17
#   ASHVAULT_SIM_RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-26-5

set -euo pipefail

SIM_NAME="${ASHVAULT_SIM_NAME:-AshVault}"
DEVICE_TYPE="${ASHVAULT_SIM_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-17}"

pick_runtime() {
  if [[ -n "${ASHVAULT_SIM_RUNTIME:-}" ]]; then
    echo "$ASHVAULT_SIM_RUNTIME"
    return
  fi
  xcrun simctl list runtimes available -j \
    | python3 -c "
import json, sys
runtimes = json.load(sys.stdin).get('runtimes', [])
ios = [r for r in runtimes if r.get('isAvailable') and 'iOS' in r.get('name', '')]
ios.sort(key=lambda r: r.get('version', ''), reverse=True)
if not ios:
    sys.exit('No available iOS simulator runtime found')
print(ios[0]['identifier'])
"
}

find_udid() {
  xcrun simctl list devices available -j \
    | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin).get('devices', {})
for runtime_devices in data.values():
    for dev in runtime_devices:
        if dev.get('name') == name and dev.get('isAvailable', True):
            print(dev['udid'])
            sys.exit(0)
" "$SIM_NAME"
}

ensure_simulator() {
  local udid
  udid="$(find_udid || true)"
  if [[ -z "$udid" ]]; then
    local runtime
    runtime="$(pick_runtime)"
    udid="$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$runtime")"
    echo "Created simulator '$SIM_NAME' ($udid) on $runtime" >&2
  fi
  echo "$udid"
}

udid="$(ensure_simulator)"
destination="platform=iOS Simulator,id=${udid}"

case "${1:-}" in
  --export)
    printf 'export ASHVAULT_SIM_DESTINATION=%q\n' "$destination"
    ;;
  --udid)
    echo "$udid"
    ;;
  *)
    echo "$destination"
    ;;
esac
