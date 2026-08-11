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
2. OpenRewrite can apply automated source and pom transformations to produce reviewable upgrade diffs.
3. The full result is visible as a clean `git diff`.

## Repo layout

- `payments-service-demo/` — minimal Java app used as the target.
- `lightwell-rules/rewrite.yml` — OpenRewrite recipe definitions.
- `lightwell-rules/lightwell-demo.mta.yaml` — MTA custom rule referencing the recipe.
- `scripts/run-demo.sh` — end-to-end helper script with strict and demo-fallback modes.
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

3. Review:
   - baseline file state
   - step 1 detection output from `mta-cli analyze`
   - step 2 remediation output from OpenRewrite
   - post-remediation compile verification result
   - resulting `git diff`

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

7. Reset and rerun when needed:

```bash
./scripts/reset-demo.sh
```

### Expected first-run behavior

- Step 1 runs `mta-cli analyze` and generates `report/static-report/index.html`.
- Step 2 runs OpenRewrite and updates files in `payments-service-demo/`.
- The script prints `git diff` so you can review exact changes.
- If you do not have access to Lightwell repositories, strict mode may fail compile verification after the version bump; fallback mode continues for demo purposes.

## Notes for narration

- The dependency bump to `2.11.0.rhlw-00001` is shown as an automated remediation action.
- The Java change to include `StandardCharsets.UTF_8` is shown as an automated source transformation.
- This avoids over-claiming that the method signature change is strictly required by `commons-io:2.11.0`.
