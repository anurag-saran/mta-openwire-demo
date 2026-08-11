package com.redhat.lightwell.openrewrite;

import org.junit.jupiter.api.Test;
import org.openrewrite.java.JavaParser;
import org.openrewrite.test.RecipeSpec;
import org.openrewrite.test.RewriteTest;
import org.openrewrite.test.TypeValidation;

import static org.openrewrite.java.Assertions.java;

class AddExplicitCharsetToFileUtilsReadTest implements RewriteTest {
    @Override
    public void defaults(RecipeSpec spec) {
        spec.recipe(new AddExplicitCharsetToFileUtilsRead())
                .parser(JavaParser.fromJavaVersion().classpath("commons-io"))
                .typeValidationOptions(TypeValidation.none());
    }

    @Test
    void rewritesSingleArgumentCall() {
        rewriteRun(
                java(
                        """
                        package com.payments.service;

                        import org.apache.commons.io.FileUtils;
                        import java.io.File;

                        class PaymentReportService {
                            String loadReport(File reportFile) throws Exception {
                                return FileUtils.readFileToString(reportFile);
                            }
                        }
                        """,
                        """
                        package com.payments.service;

                        import org.apache.commons.io.FileUtils;
                        import java.io.File;
                        import java.nio.charset.StandardCharsets;

                        class PaymentReportService {
                            String loadReport(File reportFile) throws Exception {
                                return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
                            }
                        }
                        """
                )
        );
    }

    @Test
    void noChangeWhenAlreadyModernized() {
        rewriteRun(
                java(
                        """
                        package com.payments.service;

                        import org.apache.commons.io.FileUtils;
                        import java.io.File;
                        import java.nio.charset.StandardCharsets;

                        class PaymentReportService {
                            String loadReport(File reportFile) throws Exception {
                                return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
                            }
                        }
                        """
                )
        );
    }

    @Test
    void rewritesMultipleCallSites() {
        rewriteRun(
                java(
                        """
                        package com.payments.service;

                        import org.apache.commons.io.FileUtils;
                        import java.io.File;

                        class PaymentReportService {
                            String loadReport(File reportFile) throws Exception {
                                String a = FileUtils.readFileToString(reportFile);
                                String b = FileUtils.readFileToString(reportFile);
                                return a + b;
                            }
                        }
                        """,
                        """
                        package com.payments.service;

                        import org.apache.commons.io.FileUtils;
                        import java.io.File;
                        import java.nio.charset.StandardCharsets;

                        class PaymentReportService {
                            String loadReport(File reportFile) throws Exception {
                                String a = FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
                                String b = FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
                                return a + b;
                            }
                        }
                        """
                )
        );
    }

    @Test
    void noChangeForDifferentOverload() {
        rewriteRun(
                java(
                        """
                        package com.payments.service;

                        import org.apache.commons.io.FileUtils;
                        import java.io.File;
                        import java.nio.charset.StandardCharsets;

                        class PaymentReportService {
                            String loadReport(File reportFile) throws Exception {
                                return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
                            }
                        }
                        """
                )
        );
    }
}
