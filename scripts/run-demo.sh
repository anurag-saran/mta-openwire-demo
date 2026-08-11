#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/payments-service-demo"
RULES="$ROOT/lightwell-rules"
REPORT="$ROOT/report"
REWRITE_PLUGIN_VERSION="${REWRITE_PLUGIN_VERSION:-6.45.0}"
DEMO_MODE="${DEMO_MODE:-strict}" # strict | demo-fallback

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $1" >&2
    exit 1
  }
}

need_cmd git
need_cmd mvn

mkdir -p "$REPORT"

if [ -z "${JAVA_HOME:-}" ] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home)"
fi

if [ -z "${KANTRA_DIR:-}" ] && [ -d "$ROOT/.tools/mta-8.2.0" ]; then
  export KANTRA_DIR="$ROOT/.tools/mta-8.2.0"
fi

echo "== Demo root =="
echo "$ROOT"
echo

echo "== Baseline files =="
echo "$APP/pom.xml"
echo "$APP/src/main/java/com/payments/service/PaymentReportService.java"
echo

cd "$APP"

if [ -d .git ] && ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  rm -rf .git
fi

if [ ! -d .git ]; then
  git init
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add .
  git commit -m "Initial vulnerable state"
fi

echo "== Running remediation =="
echo "== Demo mode: $DEMO_MODE =="
MTA_BIN="${MTA_BIN:-}"
if [ -z "$MTA_BIN" ] && [ -x "$ROOT/.tools/mta-cli" ]; then
  MTA_BIN="$ROOT/.tools/mta-cli"
elif [ -z "$MTA_BIN" ] && command -v mta-cli >/dev/null 2>&1; then
  MTA_BIN="$(command -v mta-cli)"
fi

if [ -n "$MTA_BIN" ]; then
  echo "[step 1/2] MTA analyze (detection/reporting)"
  echo "\"$MTA_BIN\" analyze -i \"$APP\" -o \"$REPORT\" --overwrite --rules \"$RULES/lightwell-demo.mta.yaml\" --enable-default-rulesets=false"
  if ! (
    cd "$ROOT"
    "$MTA_BIN" analyze \
      -i "$APP" \
      -o "$REPORT" \
      --overwrite \
      --rules "$RULES/lightwell-demo.mta.yaml" \
      --enable-default-rulesets=false \
      --run-local
  ); then
    if [ "$DEMO_MODE" = "demo-fallback" ]; then
      echo "WARNING: mta-cli analyze did not complete; continuing because DEMO_MODE=demo-fallback."
    else
      echo "ERROR: mta-cli analyze failed in strict mode."
      echo "Set DEMO_MODE=demo-fallback to continue remediation for presentation purposes."
      exit 3
    fi
  fi
else
  if [ "$DEMO_MODE" = "demo-fallback" ]; then
    echo "[step 1/2] MTA analyze skipped (mta-cli not found; allowed in demo-fallback)."
  else
    echo "ERROR: mta-cli not found in strict mode."
    echo "Install mta-cli or run with DEMO_MODE=demo-fallback."
    exit 4
  fi
fi

echo "[step 2/2] OpenRewrite remediation (applies code changes)"
echo "mvn -Dmaven.repo.local \"$ROOT/.m2/repository\" -Drewrite.configLocation=\"$RULES/rewrite.yml\" -Drewrite.activeRecipes=com.redhat.lightwell.ApplyLightwellRemediationDemo org.openrewrite.maven:rewrite-maven-plugin:$REWRITE_PLUGIN_VERSION:run"
mvn \
  -Dmaven.repo.local="$ROOT/.m2/repository" \
  -Drewrite.configLocation="$RULES/rewrite.yml" \
  -Drewrite.activeRecipes="com.redhat.lightwell.ApplyLightwellRemediationDemo" \
  -Drewrite.recipeArtifactCoordinates="org.openrewrite:rewrite-java:8.64.0,org.openrewrite:rewrite-maven:8.64.0" \
  "org.openrewrite.maven:rewrite-maven-plugin:$REWRITE_PLUGIN_VERSION:run"

echo
echo "== Post-remediation verification =="
if mvn -q -Dmaven.repo.local="$ROOT/.m2/repository" -DskipTests compile; then
  echo "Verification: compile succeeded."
else
  if [ "$DEMO_MODE" = "demo-fallback" ]; then
    echo "Verification: compile failed (allowed in demo-fallback mode)."
  else
    echo "ERROR: compile verification failed in strict mode."
    exit 5
  fi
fi

echo
echo "== Demo result: git diff =="
git --no-pager diff

echo
echo "== Report output =="
ls -la "$REPORT"
