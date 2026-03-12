#!/bin/bash
# Start the C++ counter publisher for local Flutter development.
#
# Usage:
#   ./scripts/dev.sh              # peer mode (desktop)
#   ./scripts/dev.sh --router     # start zenohd + client
#   ./scripts/dev.sh --router --ip 192.168.x  # router IP

set -euo pipefail

ZENOH_COUNTER_CPP="${ZENOH_COUNTER_CPP:-../zenoh-counter-cpp}"
ZENOH_DART="${ZENOH_DART:-../zenoh_dart}"

cleanup() {
  if [[ -n "${ROUTER_PID:-}" ]]; then
    kill "$ROUTER_PID" 2>/dev/null || true
  fi
}

case "${1:-}" in
  --router)
    trap cleanup EXIT
    echo "Starting zenohd router..."
    ZENOHD="${ZENOH_DART}/extern/zenoh/target/release/zenohd"
    "${ZENOHD}" &
    ROUTER_PID=$!
    sleep 1
    echo "Starting C++ counter publisher (client mode)..."
    "${ZENOH_COUNTER_CPP}/build/counter_pub" \
      -e tcp/localhost:7447
    ;;
  *)
    echo "Starting C++ counter publisher (peer mode)..."
    "${ZENOH_COUNTER_CPP}/build/counter_pub" \
      -l tcp/0.0.0.0:7447
    ;;
esac
