package com.redhat.lightwell.openrewrite;

import org.openrewrite.ExecutionContext;
import org.openrewrite.Preconditions;
import org.openrewrite.Recipe;
import org.openrewrite.TreeVisitor;
import org.openrewrite.java.JavaIsoVisitor;
import org.openrewrite.java.JavaTemplate;
import org.openrewrite.java.search.UsesMethod;
import org.openrewrite.java.tree.Expression;
import org.openrewrite.java.tree.J;
import org.openrewrite.java.MethodMatcher;

/**
 * AST-aware modernization for FileUtils.readFileToString(File):
 * adds StandardCharsets.UTF_8 as the second argument only when the
 * single-argument overload is used.
 */
public class AddExplicitCharsetToFileUtilsRead extends Recipe {
    private static final MethodMatcher ONE_ARG_READ =
            new MethodMatcher("org.apache.commons.io.FileUtils readFileToString(java.io.File)");

    @Override
    public String getDisplayName() {
        return "Add explicit charset to FileUtils.readFileToString";
    }

    @Override
    public String getDescription() {
        return "Rewrites one-argument FileUtils.readFileToString(File) calls to include StandardCharsets.UTF_8.";
    }

    @Override
    public TreeVisitor<?, ExecutionContext> getVisitor() {
        return Preconditions.check(new UsesMethod<>(ONE_ARG_READ), new JavaIsoVisitor<>() {
            private final JavaTemplate addCharsetTemplate = JavaTemplate.builder(
                    "FileUtils.readFileToString(#{any(java.io.File)}, StandardCharsets.UTF_8)")
                    .imports("org.apache.commons.io.FileUtils", "java.nio.charset.StandardCharsets")
                    .build();

            @Override
            public J.MethodInvocation visitMethodInvocation(J.MethodInvocation method, ExecutionContext ctx) {
                J.MethodInvocation m = super.visitMethodInvocation(method, ctx);
                if (!ONE_ARG_READ.matches(m) || m.getArguments().size() != 1) {
                    return m;
                }

                Expression fileArg = m.getArguments().get(0);
                J.MethodInvocation rewritten = addCharsetTemplate.apply(
                        getCursor(),
                        m.getCoordinates().replace(),
                        fileArg);
                maybeAddImport("java.nio.charset.StandardCharsets");
                return rewritten;
            }
        });
    }
}
