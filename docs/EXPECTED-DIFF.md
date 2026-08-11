# Expected Diff (Demo Success Criteria)

Use this as a visual fallback if tooling setup is flaky during the call.

## 1) `pom.xml` dependency version changes

```diff
-            <version>2.11.0</version>
+            <version>2.11.0.rhlw-00001</version>
```

## 2) Java callsite modernized with explicit charset

`payments-service-demo/src/main/java/com/payments/service/PaymentReportService.java`

```diff
 package com.payments.service;
 
 import org.apache.commons.io.FileUtils;
+import java.nio.charset.StandardCharsets;
 import java.io.File;
 
 public class PaymentReportService {
     public String loadReport(File reportFile) throws Exception {
-        return FileUtils.readFileToString(reportFile);
+        return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
     }
 }
```

## 3) Narration line

"This proves two automation layers: dependency remediation in `pom.xml` and AST-safe source rewrite (import + invocation argument), all generated without manual editing."
