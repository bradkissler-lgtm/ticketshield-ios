#!/bin/bash
# Build, test, and capture 6.7-inch App Store screenshots on a GitHub-hosted macOS runner.
# Does not sign for distribution and does not read Apple credentials.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "xcode: $(xcodebuild -version | tr '\n' ' ')"
xcrun simctl list devices >/dev/null

SELECTION="$(python3 scripts/select-6.7-simulator.py)"
DEVICE_NAME="$(printf '%s' "$SELECTION" | cut -f1)"
DEVICE_TYPE="$(printf '%s' "$SELECTION" | cut -f2)"
RUNTIME_ID="$(printf '%s' "$SELECTION" | cut -f3)"

UDID="$(xcrun simctl create "ParkShield-6.7" "$DEVICE_TYPE" "$RUNTIME_ID")"
echo "created simulator $DEVICE_NAME $UDID"

cleanup() {
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl ui "$UDID" appearance light || true

DERIVED="$ROOT/build/DerivedData"
DESTINATION="platform=iOS Simulator,id=$UDID"

echo "building ParkShield (simulator, ad-hoc, no team)"
xcodebuild \
  -project TicketShield.xcodeproj \
  -scheme TicketShield \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP="$(find "$DERIVED/Build/Products" -name 'TicketShield.app' -type d | head -n 1)"
if [ -z "$APP" ]; then
  echo "simulator build did not produce TicketShield.app" >&2
  exit 1
fi
echo "app: $APP"

set +e
xcodebuild \
  -project TicketShield.xcodeproj \
  -scheme TicketShield \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  test
TEST_STATUS=$?
set -e
echo "unit tests exit $TEST_STATUS"

OUT="$ROOT/AppStore/screenshots/6.7-inch"
mkdir -p "$OUT"
rm -f "$OUT"/*.png

xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularMode active \
  --cellularBars 4 \
  --wifiMode active \
  --wifiBars 3 || true

capture() {
  local name="$1"
  local file="$2"
  xcrun simctl terminate "$UDID" com.vancap.ticketshield >/dev/null 2>&1 || true
  local container=""
  container="$(xcrun simctl get_app_container "$UDID" com.vancap.ticketshield data 2>/dev/null || true)"
  if [ -n "$container" ]; then
    rm -f "$container/Documents/screenshot-ready"
  fi
  xcrun simctl launch "$UDID" com.vancap.ticketshield --screenshot "$name" >/dev/null
  local ready=""
  local i
  for i in $(seq 1 60); do
    container="$(xcrun simctl get_app_container "$UDID" com.vancap.ticketshield data 2>/dev/null || true)"
    ready="${container}/Documents/screenshot-ready"
    if [ -n "$container" ] && [ -f "$ready" ]; then
      break
    fi
    sleep 0.5
  done
  if [ ! -f "$ready" ]; then
    echo "timed out waiting for screenshot screen '$name'" >&2
    xcrun simctl io "$UDID" screenshot "$OUT/${file}.partial.png" || true
    exit 1
  fi
  sleep 0.4
  xcrun simctl io "$UDID" screenshot "$OUT/$file"
  local width height
  width="$(sips -g pixelWidth "$OUT/$file" | awk '/pixelWidth/{print $2}')"
  height="$(sips -g pixelHeight "$OUT/$file" | awk '/pixelHeight/{print $2}')"
  echo "$file ${width}x${height}"
  if { [ "$width" = "1290" ] && [ "$height" = "2796" ]; } || { [ "$width" = "1284" ] && [ "$height" = "2778" ]; }; then
    return 0
  fi
  echo "screenshot is ${width}x${height}, not a 6.7-inch App Store size (1290x2796 or 1284x2778)" >&2
  exit 1
}

capture empty 01-empty-home.png
capture confirm 02-confirm-schedule.png
capture saved 03-saved-spot.png
capture detail 04-moved-car.png
capture paywall 05-pro-paywall.png

printf '%s\n' "$DEVICE_NAME" > "$OUT/device.txt"
echo "screenshots written to $OUT"
exit "$TEST_STATUS"
