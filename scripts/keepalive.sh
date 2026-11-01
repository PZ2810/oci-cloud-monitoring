#!/usr/bin/env bash
# keepalive.sh — Prevent OCI Always-Free instance reclamation.
# Schedule via cron: 0 */3 * * * /path/to/scripts/keepalive.sh >> /var/log/keepalive.log 2>&1
#
# OCI may reclaim idle Always-Free instances. This generates
# a brief CPU load to prove the instance is in use.

set -euo pipefail

DURATION="1800"    # 30 minutes
CPU_LOAD="25"      # 25% CPU

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Starting keepalive: ${CPU_LOAD}% CPU for ${DURATION}s"

if ! command -v stress-ng &>/dev/null; then
  echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] ERROR: stress-ng not installed"
  exit 1
fi

stress-ng --cpu 1 --cpu-load "${CPU_LOAD}" --timeout "${DURATION}s" --quiet

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Keepalive completed"
