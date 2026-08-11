package com.payments.service;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.nio.charset.StandardCharsets;

public class PaymentReportService {
    public String loadReport(File reportFile) throws Exception {
        return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
    }
}
