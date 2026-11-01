#!/usr/bin/env bash
# test-alert.sh — Generate synthetic CPU load to validate the alerting pipeline.
# Usage: ./scripts/test-alert.sh [duration_seconds]
#
# This script:
#   1. Fires stress-ng on the host to push CPU > 80%
#   2. Waits for Prometheus to pick up the spike
#   3. Checks Alertmanager for a firing alert
#   4. Cleans up and reports results

set -euo pipefail

DURATION="${1:-120}"
ALERTMANAGER_URL="http://127.0.0.1:9093"

echo "============================================="
echo "  Alert Pipeline Smoke Test"
echo "============================================="
echo ""

# --- Pre-flight checks ---
if ! command -v stress-ng &>/dev/null; then
  echo "⚠  stress-ng not found. Installing..."
  sudo apt-get update -qq && sudo apt-get install -y -qq stress-ng
fi

if ! curl -sf "${ALERTMANAGER_URL}/-/healthy" &>/dev/null; then
  echo "❌ Alertmanager is not reachable at ${ALERTMANAGER_URL}"
  echo "   Make sure 'docker compose up -d' has been run."
  exit 1
fi

echo "✅ Pre-flight checks passed"
echo ""

# --- Generate CPU load ---
CORES=$(nproc)
echo "🔥 Generating CPU stress on ${CORES} cores for ${DURATION}s..."
stress-ng --cpu "${CORES}" --cpu-load 90 --timeout "${DURATION}s" --quiet &
STRESS_PID=$!

cleanup() {
  echo ""
  echo "🧹 Cleaning up stress-ng (PID ${STRESS_PID})..."
  kill "${STRESS_PID}" 2>/dev/null || true
  wait "${STRESS_PID}" 2>/dev/null || true
  echo "✅ Stress test stopped."
}
trap cleanup EXIT

# --- Wait for Prometheus to detect the spike ---
echo "⏳ Waiting 90 seconds for Prometheus to evaluate alert rules..."
sleep 90

# --- Check Alertmanager for firing alerts ---
echo ""
echo "🔍 Checking Alertmanager for firing alerts..."

ALERTS=$(curl -sf "${ALERTMANAGER_URL}/api/v2/alerts" 2>/dev/null || echo "[]")
FIRING=$(echo "${ALERTS}" | grep -c '"status":"firing"' || true)

if [ "${FIRING}" -gt 0 ]; then
  echo "✅ SUCCESS — Found ${FIRING} firing alert(s) in Alertmanager!"
  echo ""
  echo "Alert details:"
  echo "${ALERTS}" | python3 -m json.tool 2>/dev/null || echo "${ALERTS}"
else
  echo "⚠  No firing alerts found yet."
  echo "   This can happen if the 'for' duration hasn't elapsed."
  echo "   Check Prometheus at http://127.0.0.1:9090/alerts"
  echo ""
  echo "   Raw Alertmanager response:"
  echo "${ALERTS}"
fi

echo ""
echo "============================================="
echo "  Test complete. Check Discord for notification."
echo "============================================="
