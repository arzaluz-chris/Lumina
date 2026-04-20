#!/usr/bin/env bash
# Runs the automated App Store screenshot capture for Lumina.
#
# Boots a simulator, pins the status bar to 9:41 with full signal /
# Wi-Fi / battery, invokes the LuminaUITests screenshot suite, then
# extracts every screenshot attachment out of the xcresult bundle
# as PNGs under `fastlane/screenshots/<device>/es-MX/`.
#
# Usage:
#   ./scripts/run_screenshots.sh                 # defaults to iphone
#   ./scripts/run_screenshots.sh --device ipad   # iPad mini
#   ./scripts/run_screenshots.sh --device iphone
#
# Requirements:
#   - Xcode 26 with the target device type + iOS 26.x runtime installed.

set -euo pipefail

DEVICE="iphone"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

case "$DEVICE" in
  iphone)
    SIM_NAME="Lumina-iPhone15ProMax"
    DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max"
    OUT_SUBDIR="iPhone15ProMax"
    ;;
  ipad)
    SIM_NAME="Lumina-iPadMini"
    DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro"
    OUT_SUBDIR="iPadMini"
    ;;
  *)
    echo "Unsupported device: $DEVICE (expected: iphone | ipad)"
    exit 2
    ;;
esac

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$PROJECT_ROOT/Lumina.xcodeproj"
SCHEME="Lumina"
OUT_DIR="$PROJECT_ROOT/fastlane/screenshots/$OUT_SUBDIR/es-MX"
XCRESULT="$PROJECT_ROOT/build/LuminaUITests-$OUT_SUBDIR.xcresult"
DERIVED="$PROJECT_ROOT/build/DerivedData"

mkdir -p "$OUT_DIR"
mkdir -p "$PROJECT_ROOT/build"

echo "› Device: $DEVICE ($DEVICE_TYPE)"

# ---------------------------------------------------------------------
# 1. Pick the newest installed iOS runtime.
# ---------------------------------------------------------------------
RUNTIME_ID=$(xcrun simctl list runtimes available -j \
  | python3 -c "import json,sys; rts=[r for r in json.load(sys.stdin)['runtimes'] if r['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS')]; rts.sort(key=lambda r: r['version'], reverse=True); print(rts[0]['identifier']) if rts else sys.exit('no iOS runtime')")
echo "› Using runtime: $RUNTIME_ID"

# ---------------------------------------------------------------------
# 2. Create or reuse the simulator.
# ---------------------------------------------------------------------
SIM_UDID=$(xcrun simctl list devices -j \
  | python3 -c "import json,sys; d=json.load(sys.stdin); udid=''; [udid:=dev['udid'] for _, devs in d['devices'].items() for dev in devs if dev['name']=='$SIM_NAME']; print(udid)")

if [[ -z "$SIM_UDID" ]]; then
  echo "› Creating simulator: $SIM_NAME"
  SIM_UDID=$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$RUNTIME_ID")
else
  echo "› Reusing simulator: $SIM_NAME ($SIM_UDID)"
fi

# ---------------------------------------------------------------------
# 3. Boot + wait until fully booted.
# ---------------------------------------------------------------------
xcrun simctl bootstatus "$SIM_UDID" -b
echo "› Simulator booted"

# ---------------------------------------------------------------------
# 4. Pin the status bar: 9:41, full signal, charged.
#    On iPad the cellular fields are ignored for Wi-Fi-only models —
#    passing them is still harmless.
# ---------------------------------------------------------------------
xcrun simctl status_bar "$SIM_UDID" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --operatorName "" \
  --batteryState charged \
  --batteryLevel 100
echo "› Status bar pinned"

# ---------------------------------------------------------------------
# 5. Wipe any previous xcresult + run tests.
# ---------------------------------------------------------------------
rm -rf "$XCRESULT"
echo "› Running UI tests (~2 min)"
set +e
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$SIM_UDID" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$XCRESULT" \
  -only-testing:LuminaUITests \
  -quiet 2>&1 | tail -40
TEST_EXIT=$?
set -e

if [[ $TEST_EXIT -ne 0 ]]; then
  echo "› xcodebuild test exited with $TEST_EXIT — continuing to extract any captured screenshots"
fi

# ---------------------------------------------------------------------
# 6. Extract every PNG attachment whose name starts with a 2-digit
#    prefix out of the xcresult bundle.
# ---------------------------------------------------------------------
echo "› Extracting screenshots to $OUT_DIR"
rm -f "$OUT_DIR"/*.png 2>/dev/null || true

python3 "$PROJECT_ROOT/scripts/extract_screenshots.py" "$XCRESULT" "$OUT_DIR"

COUNT=$(ls -1 "$OUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "› Extracted $COUNT screenshots."
ls -1 "$OUT_DIR"

# ---------------------------------------------------------------------
# 7. Unpin status bar so the simulator isn't left in a weird state.
# ---------------------------------------------------------------------
xcrun simctl status_bar "$SIM_UDID" clear || true

echo "✓ Done. Screenshots in $OUT_DIR"
