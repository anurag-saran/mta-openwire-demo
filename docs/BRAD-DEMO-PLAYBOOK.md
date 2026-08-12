# Brad Demo Playbook (10 minutes)

## Strategic message

1. **Automation over manual effort**: MTA applies remediation rules automatically.
2. **AST-aware refactoring**: OpenRewrite updates Java code structure, not just text (full scope).
3. **Lightwell value**: safer remediation path with reduced retest scope burden.
4. **Recipe delivery**: recipes can be a local `rewrite.yml` or a Maven-published recipes JAR.

## Show this baseline

- `payments-service-demo/pom.xml` uses `commons-io:2.11.0`.
- `PaymentReportService` uses `FileUtils.readFileToString(reportFile)`.

## Run

Full demo (pom + Java, local rewrite.yml):

```bash
./scripts/run-demo.sh
```

Pom-only demo (dependency bump only, local rewrite.yml):

```bash
DEMO_MODE=demo-fallback DEMO_SCOPE=pom-only ./scripts/run-demo.sh
```

Pom-only demo with Maven recipe source (same diff, recipes from JAR):

```bash
DEMO_MODE=demo-fallback DEMO_SCOPE=pom-only RECIPE_SOURCE=maven ./scripts/run-demo.sh
```

`run-demo.sh` uses `mta-cli` if installed, otherwise falls back to `rewrite` CLI.

## Reveal

```bash
cd payments-service-demo
git diff
```

Callouts (full scope):

- `pom.xml` changed to `2.11.0.rhlw-00001`.
- Java source changed via OpenRewrite recipe intent (explicit charset + import).

Callouts (pom-only scope):

- `pom.xml` changed to `2.11.0.rhlw-00001`.
- Java source is unchanged.

Callouts (recipe source):

- `RECIPE_SOURCE=local` (default): `-Drewrite.configLocation=lightwell-rules/rewrite.yml`
- `RECIPE_SOURCE=maven`: no local config file; recipes loaded from `com.redhat.lightwell:lightwell-openrewrite-recipes` via `-Drewrite.recipeArtifactCoordinates`
- Same resulting diff either way

If tooling setup fails live, use `docs/EXPECTED-DIFF.md` as the reference output.

## Reset for next run

```bash
./scripts/reset-demo.sh
```
