#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/payments-service-demo"
RULES="$ROOT/lightwell-rules"
REPORT="$ROOT/report"
CUSTOM_RECIPES_DIR="$ROOT/custom-recipes"
LIGHTWELL_RECIPES_DIR="$ROOT/lightwell-recipes"
REWRITE_PLUGIN_VERSION="${REWRITE_PLUGIN_VERSION:-6.45.0}"
DEMO_MODE="${DEMO_MODE:-strict}" # strict | demo-fallback
DEMO_SCOPE="${DEMO_SCOPE:-full}" # full | pom-only
RECIPE_SOURCE="${RECIPE_SOURCE:-local}" # local | maven

case "$DEMO_SCOPE" in
  full)
    ACTIVE_RECIPE="com.redhat.lightwell.ApplyLightwellRemediationDemo"
    ;;
  pom-only)
    ACTIVE_RECIPE="com.redhat.lightwell.ApplyLightwellPomOnlyDemo"
    ;;
  *)
    echo "ERROR: DEMO_SCOPE must be 'full' or 'pom-only' (got: $DEMO_SCOPE)" >&2
    exit 2
    ;;
esac

case "$RECIPE_SOURCE" in
  local)
    if [ "$DEMO_SCOPE" = "full" ]; then
      RECIPE_ARTIFACT_COORDS="org.openrewrite:rewrite-java:8.64.0,org.openrewrite:rewrite-maven:8.64.0,com.redhat.lightwell:custom-recipes:1.0.0-SNAPSHOT"
    else
      RECIPE_ARTIFACT_COORDS="org.openrewrite:rewrite-java:8.64.0,org.openrewrite:rewrite-maven:8.64.0"
    fi
    ;;
  maven)
    RECIPE_ARTIFACT_COORDS="org.openrewrite:rewrite-java:8.64.0,org.openrewrite:rewrite-maven:8.64.0,com.redhat.lightwell:lightwell-openrewrite-recipes:1.0.0-SNAPSHOT"
    ;;
  *)
    echo "ERROR: RECIPE_SOURCE must be 'local' or 'maven' (got: $RECIPE_SOURCE)" >&2
    exit 2
    ;;
esac

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $1" >&2
    exit 1
  }
}

# Print the exact command about to run so the demo is easy to follow.
run_cmd() {
  echo
  echo ">>> $*"
  echo
  "$@"
}

need_cmd git
need_cmd mvn

mkdir -p "$REPORT"
LOCAL_REPO="$ROOT/.m2/repository"
DEMO_SETTINGS="$ROOT/.m2/demo-fallback-settings.xml"

mvn_demo() {
  if [ "$DEMO_MODE" = "demo-fallback" ]; then
    mvn -s "$DEMO_SETTINGS" -Dmaven.repo.local="$LOCAL_REPO" "$@"
  else
    mvn -Dmaven.repo.local="$LOCAL_REPO" "$@"
  fi
}

ensure_demo_fallback_artifacts() {
  local src_jar="$LOCAL_REPO/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar"
  local dest_jar="$LOCAL_REPO/commons-io/commons-io/2.11.0.rhlw-00001/commons-io-2.11.0.rhlw-00001.jar"
  local tmp

  mkdir -p "$ROOT/.m2"
  cat >"$DEMO_SETTINGS" <<'EOF'
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
  <profiles>
    <profile>
      <id>central-only</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>https://repo.maven.apache.org/maven2</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>https://repo.maven.apache.org/maven2</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>central-only</activeProfile>
  </activeProfiles>
</settings>
EOF

  if [ ! -f "$src_jar" ]; then
    echo "Downloading commons-io:2.11.0 into local demo repo..."
    mvn_demo -q \
      org.apache.maven.plugins:maven-dependency-plugin:3.6.1:get \
      -Dartifact=commons-io:commons-io:2.11.0
  fi

  if [ -f "$dest_jar" ]; then
    echo "Using existing local stand-in for commons-io:2.11.0.rhlw-00001"
    return 0
  fi

  echo "Installing local stand-in for commons-io:2.11.0.rhlw-00001 (no Lightwell credentials required)..."
  rm -rf "$LOCAL_REPO/commons-io/commons-io/2.11.0.rhlw-00001"
  tmp="$(mktemp -d)"
  cat >"$tmp/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>commons-io</groupId>
  <artifactId>commons-io</artifactId>
  <version>2.11.0.rhlw-00001</version>
  <packaging>jar</packaging>
  <name>Apache Commons IO (Lightwell demo stand-in)</name>
</project>
EOF
  cp "$src_jar" "$tmp/commons-io.jar"
  mvn_demo -q \
    org.apache.maven.plugins:maven-install-plugin:3.1.1:install-file \
    -DgroupId=commons-io \
    -DartifactId=commons-io \
    -Dversion=2.11.0.rhlw-00001 \
    -Dpackaging=jar \
    -Dfile="$tmp/commons-io.jar" \
    -DpomFile="$tmp/pom.xml"
  rm -rf "$tmp"
}

apply_expected_demo_changes() {
  local pom="$APP/pom.xml"
  local java="$APP/src/main/java/com/payments/service/PaymentReportService.java"

  python3 - "$DEMO_SCOPE" "$pom" "$java" <<'PY'
import pathlib, sys
scope, pom_path, java_path = sys.argv[1:4]
pom = pathlib.Path(pom_path)
pom.write_text(pom.read_text().replace("<version>2.11.0</version>", "<version>2.11.0.rhlw-00001</version>", 1))
if scope == "pom-only":
    raise SystemExit(0)
pathlib.Path(java_path).write_text(
    "package com.payments.service;\n"
    "\n"
    "import org.apache.commons.io.FileUtils;\n"
    "\n"
    "import java.io.File;\n"
    "import java.nio.charset.StandardCharsets;\n"
    "\n"
    "public class PaymentReportService {\n"
    "    public String loadReport(File reportFile) throws Exception {\n"
    "        return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);\n"
    "    }\n"
    "}\n"
)
PY
}

if [ -z "${JAVA_HOME:-}" ] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home)"
fi

if [ -z "${KANTRA_DIR:-}" ] && [ -d "$ROOT/.tools/mta-8.2.0" ]; then
  export KANTRA_DIR="$ROOT/.tools/mta-8.2.0"
fi

if [ "$DEMO_MODE" = "demo-fallback" ]; then
  ensure_demo_fallback_artifacts
fi

echo "== Demo root =="
echo "$ROOT"
echo
echo "== Config =="
echo "DEMO_MODE=$DEMO_MODE"
echo "DEMO_SCOPE=$DEMO_SCOPE"
echo "RECIPE_SOURCE=$RECIPE_SOURCE"
echo "ACTIVE_RECIPE=$ACTIVE_RECIPE"
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
MTA_BIN="${MTA_BIN:-}"
if [ -z "$MTA_BIN" ] && [ -x "$ROOT/.tools/mta-cli" ]; then
  MTA_BIN="$ROOT/.tools/mta-cli"
elif [ -z "$MTA_BIN" ] && command -v mta-cli >/dev/null 2>&1; then
  MTA_BIN="$(command -v mta-cli)"
fi

if [ -n "$MTA_BIN" ]; then
  echo "[step 1/2] MTA analyze (detection/reporting — does not edit source)"
  if ! (
    cd "$ROOT"
    run_cmd "$MTA_BIN" analyze \
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

echo
echo "[step 2/2] OpenRewrite remediation (applies code changes)"
REWRITE_ARGS=(
  -Drewrite.activeRecipes="$ACTIVE_RECIPE"
  -Drewrite.recipeArtifactCoordinates="$RECIPE_ARTIFACT_COORDS"
)

if [ "$RECIPE_SOURCE" = "maven" ]; then
  echo "Recipe source=maven: install recipes JAR, then run OpenRewrite without local rewrite.yml"
  echo
  echo ">>> mvn -f $CUSTOM_RECIPES_DIR/pom.xml -DskipTests install"
  echo
  mvn_demo -q -f "$CUSTOM_RECIPES_DIR/pom.xml" -DskipTests install

  echo ">>> mvn -f $LIGHTWELL_RECIPES_DIR/pom.xml -DskipTests install"
  echo
  mvn_demo -q -f "$LIGHTWELL_RECIPES_DIR/pom.xml" -DskipTests install
else
  if [ "$DEMO_SCOPE" = "full" ]; then
    echo ">>> mvn -f $CUSTOM_RECIPES_DIR/pom.xml -DskipTests install"
    echo
    mvn_demo -q -f "$CUSTOM_RECIPES_DIR/pom.xml" -DskipTests install
  else
    echo "Skipping custom AST recipe build (DEMO_SCOPE=pom-only)."
  fi
  REWRITE_ARGS+=(-Drewrite.configLocation="$RULES/rewrite.yml")
fi

# Show the full OpenRewrite command, then run it (mvn_demo adds -s/-Dmaven.repo.local).
echo ">>> mvn -Dmaven.repo.local=\"$LOCAL_REPO\" \\"
if [ "$RECIPE_SOURCE" = "local" ]; then
  echo "      -Drewrite.configLocation=\"$RULES/rewrite.yml\" \\"
fi
echo "      -Drewrite.activeRecipes=$ACTIVE_RECIPE \\"
echo "      -Drewrite.recipeArtifactCoordinates=$RECIPE_ARTIFACT_COORDS \\"
echo "      org.openrewrite.maven:rewrite-maven-plugin:$REWRITE_PLUGIN_VERSION:run"
echo

if ! mvn_demo \
  "${REWRITE_ARGS[@]}" \
  "org.openrewrite.maven:rewrite-maven-plugin:$REWRITE_PLUGIN_VERSION:run"
then
  if [ "$DEMO_MODE" = "demo-fallback" ]; then
    echo "WARNING: OpenRewrite failed; applying expected demo changes for presentation."
    apply_expected_demo_changes
  else
    echo "ERROR: OpenRewrite remediation failed in strict mode."
    echo "Set DEMO_MODE=demo-fallback to continue without Lightwell Maven credentials."
    exit 6
  fi
fi

echo
echo "== Post-remediation verification =="
echo ">>> mvn -DskipTests compile"
echo
if mvn_demo -q -DskipTests compile; then
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
echo ">>> git --no-pager diff"
echo
git --no-pager diff

echo
echo "== Report =="
echo "Open:  open $REPORT/static-report/index.html"
echo "Reset: ./scripts/reset-demo.sh"
echo
ls -la "$REPORT"
