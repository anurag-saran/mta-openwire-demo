#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/payments-service-demo"
RULES="$ROOT/lightwell-rules/rewrite.yml"

if ! command -v rewrite >/dev/null 2>&1; then
  echo "ERROR: rewrite CLI is not installed." >&2
  exit 2
fi

echo "Running OpenRewrite fallback directly against source tree..."
echo "rewrite run --config \"$RULES\" --recipes com.redhat.lightwell.ApplyLightwellRemediationDemo --dir \"$APP\""

# This is the standard intent for rewrite CLI; exact flags can vary slightly by version.
rewrite run \
  --config "$RULES" \
  --recipes com.redhat.lightwell.ApplyLightwellRemediationDemo \
  --dir "$APP"

echo "OpenRewrite fallback completed."
