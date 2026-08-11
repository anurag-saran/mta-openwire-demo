# Brad Demo Playbook (10 minutes)

## Strategic message

1. **Automation over manual effort**: MTA applies remediation rules automatically.
2. **AST-aware refactoring**: OpenRewrite updates Java code structure, not just text.
3. **Lightwell value**: safer remediation path with reduced retest scope burden.

## Show this baseline

- `payments-service-demo/pom.xml` uses `commons-io:2.11.0`.
- `PaymentReportService` uses `FileUtils.readFileToString(reportFile)`.

## Run

```bash
./scripts/run-demo.sh
```

`run-demo.sh` uses `mta-cli` if installed, otherwise falls back to `rewrite` CLI.

## Reveal

```bash
cd payments-service-demo
git diff
```

Callouts:

- `pom.xml` changed to `2.11.0.rhlw-00001`.
- Java source changed via OpenRewrite recipe intent (explicit charset + import).
- If tooling setup fails live, use `docs/EXPECTED-DIFF.md` as the reference output.

## Reset for next run

```bash
./scripts/reset-demo.sh
```
