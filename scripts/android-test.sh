#!/bin/bash
# Start WiFi hotspot + zenohd router + C++ publisher for Android testing.
#
# Requires: nmcli, ethernet connected, WiFi adapter idle.
# The Android phone connects to the hotspot, then the Flutter app
# connects to tcp/<host-hotspot-ip>:7447.
#
# Usage:
#   ./scripts/android-test.sh                # defaults
#   ./scripts/android-test.sh --ssid MyNet   # custom SSID
#   ./scripts/android-test.sh --no-hotspot   # skip hotspot (already up)
#   ./scripts/android-test.sh --stop         # tear down hotspot
#
# Environment variables:
#   ZENOH_COUNTER_CPP  Path to zenoh-counter-cpp repo
#                      (default: ../zenoh-counter-cpp)
#   ZENOH_DART         Path to zenoh_dart repo
#                      (default: ../zenoh_dart)
#   WIFI_IFACE         WiFi interface for hotspot
#                      (default: wlp0s20f3)
#   HOTSPOT_SSID       Hotspot network name (default: zenoh-test)
#   HOTSPOT_PASS       Hotspot password (default: zenoh1234)

set -euo pipefail

# --- Configuration ---

ZENOH_COUNTER_CPP="${ZENOH_COUNTER_CPP:-../zenoh-counter-cpp}"
ZENOH_DART="${ZENOH_DART:-../zenoh_dart}"
WIFI_IFACE="${WIFI_IFACE:-wlp0s20f3}"
HOTSPOT_SSID="${HOTSPOT_SSID:-zenoh-test}"
HOTSPOT_PASS="${HOTSPOT_PASS:-zenoh1234}"
HOTSPOT_CONN="Hotspot"
SKIP_HOTSPOT=false
ROUTER_PID=""
PUB_PID=""

ZENOHD="${ZENOH_DART}/extern/zenoh/target/release/zenohd"
COUNTER_PUB="${ZENOH_COUNTER_CPP}/build/app/counter_pub"

# --- Parse arguments ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssid)
      HOTSPOT_SSID="$2"
      shift 2
      ;;
    --password)
      HOTSPOT_PASS="$2"
      shift 2
      ;;
    --iface)
      WIFI_IFACE="$2"
      shift 2
      ;;
    --no-hotspot)
      SKIP_HOTSPOT=true
      shift
      ;;
    --stop)
      echo "Stopping hotspot..."
      nmcli connection down "$HOTSPOT_CONN" 2>/dev/null || true
      echo "Done."
      exit 0
      ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- Preflight checks ---

preflight() {
  local ok=true

  if ! command -v nmcli &>/dev/null; then
    echo "ERROR: nmcli not found. Install network-manager." >&2
    ok=false
  fi

  if [[ ! -x "$ZENOHD" ]]; then
    echo "ERROR: zenohd not found at $ZENOHD" >&2
    echo "  Build it: cd ${ZENOH_DART}/extern/zenoh && cargo build --release" >&2
    ok=false
  fi

  if [[ ! -x "$COUNTER_PUB" ]]; then
    echo "ERROR: counter_pub not found at $COUNTER_PUB" >&2
    echo "  Build it: cd ${ZENOH_COUNTER_CPP} && cmake --build build" >&2
    ok=false
  fi

  if [[ "$SKIP_HOTSPOT" == false ]]; then
    local wifi_state
    wifi_state=$(nmcli -t -f DEVICE,STATE device status \
      | grep "^${WIFI_IFACE}:" | cut -d: -f2)
    if [[ "$wifi_state" == "unavailable" ]]; then
      echo "ERROR: WiFi interface $WIFI_IFACE is unavailable." >&2
      echo "  Check: rfkill list" >&2
      ok=false
    fi
  fi

  if [[ "$ok" == false ]]; then
    exit 1
  fi
}

preflight

# --- Cleanup on exit ---

cleanup() {
  echo ""
  echo "Shutting down..."

  if [[ -n "$PUB_PID" ]]; then
    kill "$PUB_PID" 2>/dev/null || true
    wait "$PUB_PID" 2>/dev/null || true
    echo "  counter_pub stopped."
  fi

  if [[ -n "$ROUTER_PID" ]]; then
    kill "$ROUTER_PID" 2>/dev/null || true
    wait "$ROUTER_PID" 2>/dev/null || true
    echo "  zenohd stopped."
  fi

  # Don't auto-stop hotspot -- user may want it to persist
  echo ""
  echo "Hotspot still active. To stop: $0 --stop"
}

trap cleanup EXIT

# --- Step 1: WiFi Hotspot ---

if [[ "$SKIP_HOTSPOT" == false ]]; then
  # Check if hotspot is already active
  if nmcli connection show --active 2>/dev/null \
      | grep -q "$HOTSPOT_CONN"; then
    echo "Hotspot already active, reusing."
  else
    echo "Creating WiFi hotspot..."
    echo "  SSID:      $HOTSPOT_SSID"
    echo "  Password:  $HOTSPOT_PASS"
    echo "  Interface: $WIFI_IFACE"
    nmcli device wifi hotspot \
      ifname "$WIFI_IFACE" \
      ssid "$HOTSPOT_SSID" \
      password "$HOTSPOT_PASS"
  fi
else
  echo "Skipping hotspot setup (--no-hotspot)."
fi

# Get host IP on hotspot interface
HOST_IP=$(nmcli -t -f IP4.ADDRESS device show "$WIFI_IFACE" \
  | head -1 | cut -d: -f2 | cut -d/ -f1)

if [[ -z "$HOST_IP" ]]; then
  # Fallback: hotspot skipped or IP not yet assigned
  HOST_IP="10.42.0.1"
fi

echo ""
echo "=== Host IP: $HOST_IP ==="
echo ""

# --- Step 2: zenohd router ---

echo "Starting zenohd router on tcp/0.0.0.0:7447..."
"$ZENOHD" -l tcp/0.0.0.0:7447 &
ROUTER_PID=$!
sleep 1

if ! kill -0 "$ROUTER_PID" 2>/dev/null; then
  echo "ERROR: zenohd failed to start." >&2
  ROUTER_PID=""
  exit 1
fi

echo "  zenohd PID: $ROUTER_PID"

# --- Step 3: C++ counter publisher ---

echo "Starting counter_pub (client mode -> router)..."
"$COUNTER_PUB" -e tcp/localhost:7447 &
PUB_PID=$!
sleep 1

if ! kill -0 "$PUB_PID" 2>/dev/null; then
  echo "ERROR: counter_pub failed to start." >&2
  PUB_PID=""
  exit 1
fi

echo "  counter_pub PID: $PUB_PID"

# --- Ready ---

echo ""
echo "============================================"
echo "  Android test environment ready"
echo ""
echo "  1. Connect phone to WiFi: $HOTSPOT_SSID"
echo "     Password: $HOTSPOT_PASS"
echo ""
echo "  2. In Flutter app, enter endpoint:"
echo "     tcp/$HOST_IP:7447"
echo ""
echo "  3. Run Flutter app:"
echo "     fvm flutter run -d <device-id>"
echo ""
echo "  Press Ctrl+C to stop router + publisher."
echo "============================================"
echo ""

# Wait for publisher (foreground process)
wait "$PUB_PID" 2>/dev/null || true
PUB_PID=""
