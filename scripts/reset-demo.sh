#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/payments-service-demo"
REPORT="$ROOT/report"

cd "$APP"
if [ -d .git ]; then
  git reset --hard HEAD
  git clean -fd
fi
rm -rf target

rm -rf "$REPORT"
mkdir -p "$REPORT"

echo "Reset complete."
echo "App restored to committed baseline, report dir cleared."
