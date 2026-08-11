# MTA + OpenRewrite Lightwell Demo

This repository contains a turnkey demo you can hand to Brad.

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

## Notes for narration

- The dependency bump to `2.11.0.rhlw-00001` is shown as an automated remediation action.
- The Java change to include `StandardCharsets.UTF_8` is shown as an automated source transformation.
- This avoids over-claiming that the method signature change is strictly required by `commons-io:2.11.0`.
