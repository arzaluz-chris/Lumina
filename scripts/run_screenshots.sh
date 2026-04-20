#!/usr/bin/env bash
# Runs the automated App Store screenshot capture for Lumina.
#
# Boots an iPhone 15 Pro Max simulator, pins the status bar to 9:41
# with full signal, Wi-Fi and battery, invokes the LuminaUITests
# screenshot suite, then extracts every screenshot attachment out of
# the xcresult bundle as PNGs in `fastlane/screenshots/es-MX/`.
#
# Usage:
#   ./scripts/run_screenshots.sh
#
# Requirements:
#   - Xcode 26 with iPhone 15 Pro Max device type installed.
#   - iOS 26.x runtime installed.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$PROJECT_ROOT/Lumina.xcodeproj"
SCHEME="Lumina"
SIM_NAME="Lumina-iPhone15ProMax"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max"
OUT_DIR="$PROJECT_ROOT/fastlane/screenshots/es-MX"
XCRESULT="$PROJECT_ROOT/build/LuminaUITests.xcresult"
DERIVED="$PROJECT_ROOT/build/DerivedData"

mkdir -p "$OUT_DIR"
mkdir -p "$PROJECT_ROOT/build"

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
echo "› Running UI tests (this takes ~2 min)"
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
