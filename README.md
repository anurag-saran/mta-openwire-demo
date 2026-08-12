# MTA + OpenRewrite Lightwell Demo

This repository contains a turnkey demo you can hand to Brad.

## 30-Second Quickstart

```bash
git clone https://github.com/anurag-saran/mta-openwire-demo.git
cd mta-openwire-demo
DEMO_MODE=demo-fallback ./scripts/run-demo.sh
```

Then open `report/static-report/index.html` and review the printed `git diff`.

## What this demo proves

1. MTA can apply a Lightwell-style remediated dependency version in `pom.xml`.
2. OpenRewrite applies an AST-aware custom Java recipe for call-site modernization, plus automated `pom.xml` remediation updates.
3. The full result is visible as a clean `git diff`.

## Repo layout

- `payments-service-demo/` — minimal Java app used as the target.
- `lightwell-rules/rewrite.yml` — OpenRewrite recipe definitions for `RECIPE_SOURCE=local`.
- `lightwell-rules/lightwell-demo.mta.yaml` — MTA custom rule referencing the recipe.
- `lightwell-recipes/` — Maven module that packages the same recipes under `META-INF/rewrite/` for `RECIPE_SOURCE=maven`.
- `custom-recipes/` — custom AST-aware OpenRewrite Java recipe module and tests.
- `scripts/run-demo.sh` — end-to-end helper script with strict/fallback modes, scope, and recipe source.
- `scripts/run-openrewrite-fallback.sh` — direct OpenRewrite fallback path (legacy helper).
- `docs/EXPECTED-DIFF.md` — golden diff to show if tooling setup blocks live execution.

## Quick start

1. Ensure prerequisites are installed:
   - `git`
   - `mta-cli`
   - `mvn`
2. Run:

```bash
./scripts/run-demo.sh
```

Optional fallback mode for live demos:

```bash
DEMO_MODE=demo-fallback ./scripts/run-demo.sh
```

Pom-only scope (dependency bump in `pom.xml`, no Java source changes):

```bash
DEMO_MODE=demo-fallback DEMO_SCOPE=pom-only ./scripts/run-demo.sh
```

Same pom-only result, but load recipes from a Maven recipes JAR instead of local `rewrite.yml`:

```bash
DEMO_MODE=demo-fallback DEMO_SCOPE=pom-only RECIPE_SOURCE=maven ./scripts/run-demo.sh
```

3. Review:
   - baseline file state
   - step 1 detection output from `mta-cli analyze`
   - step 2 remediation output from OpenRewrite
   - post-remediation compile verification result
   - resulting `git diff`

### Optional: validate custom recipe tests

Run this once to validate the AST recipe scenarios directly:

```bash
mvn -f custom-recipes/pom.xml test
```

## New Contributor Setup

Use this if you are cloning the repo for the first time.

1. Clone and enter the project:

```bash
git clone https://github.com/anurag-saran/mta-openwire-demo.git
cd mta-openwire-demo
```

2. Install prerequisites:
   - Java (JDK 17+ recommended)
   - Maven
   - Git
   - `mta-cli` (recommended for the detection step)
   - Network access to Maven Central for first-time dependency resolution

3. Verify local tools:

```bash
java -version
mvn -v
git --version
```

4. Place `mta-cli` in the project-local tools folder:

```bash
mkdir -p .tools
# copy your mta-cli binary to .tools/mta-cli
chmod +x .tools/mta-cli
```

5. macOS only (if Gatekeeper blocks execution):

```bash
xattr -dr com.apple.quarantine .tools
```

6. Run demo:
   - Strict mode (recommended for CI-like validation):

```bash
./scripts/run-demo.sh
```

   - Fallback mode (recommended for first local run/demo environments):

```bash
DEMO_MODE=demo-fallback ./scripts/run-demo.sh
```

   - Pom-only scope (dependency remediation only):

```bash
DEMO_MODE=demo-fallback DEMO_SCOPE=pom-only ./scripts/run-demo.sh
```

   - Maven recipe source (same remediates, recipes loaded from installed JAR):

```bash
DEMO_MODE=demo-fallback DEMO_SCOPE=pom-only RECIPE_SOURCE=maven ./scripts/run-demo.sh
```

7. Reset and rerun when needed:

```bash
./scripts/reset-demo.sh
```

### Expected first-run behavior

- Step 1 runs `mta-cli analyze` and generates `report/static-report/index.html`.
- Step 2 runs OpenRewrite and updates files in `payments-service-demo/`.
- With default `DEMO_SCOPE=full`, step 2 builds and runs a custom AST-aware OpenRewrite Java recipe from `custom-recipes/`.
- With `DEMO_SCOPE=pom-only`, step 2 skips the custom Java recipe and only remediates `pom.xml`.
- With default `RECIPE_SOURCE=local`, recipes come from `lightwell-rules/rewrite.yml` via `-Drewrite.configLocation`.
- With `RECIPE_SOURCE=maven`, recipes come from the installed `com.redhat.lightwell:lightwell-openrewrite-recipes` JAR (`META-INF/rewrite/`) via `-Drewrite.recipeArtifactCoordinates` — no local `rewrite.yml`.
- `run-demo.sh` installs recipe modules with `-DskipTests` when needed (`DEMO_SCOPE=full` or `RECIPE_SOURCE=maven`); run `mvn -f custom-recipes/pom.xml test` separately for recipe test validation.
- The script prints `git diff` so you can review exact changes.
- If you do not have access to Lightwell repositories, strict mode may fail compile verification after the version bump; fallback mode continues for demo purposes.

## Notes for narration

- The dependency bump to `2.11.0.rhlw-00001` is shown as an automated remediation action.
- In full scope, the Java change to include `StandardCharsets.UTF_8` is performed by a custom AST-aware recipe (`com.redhat.lightwell.openrewrite.AddExplicitCharsetToFileUtilsRead`).
- This avoids over-claiming that the method signature change is strictly required by `commons-io:2.11.0`.
- Use `DEMO_SCOPE=pom-only` when you want to show dependency remediation alone.