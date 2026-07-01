package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.HostFinanceSettlementDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.service.FinanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/finance")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminFinanceController {

    private final FinanceService financeService;

    @GetMapping("/summary")
    public ResponseEntity<APIResponse<FinanceSummaryDTO>> summary(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        final LocalDate now = LocalDate.now();
        final int reportYear = year == null ? now.getYear() : year;
        final int reportMonth = month == null ? now.getMonthValue() : month;

        return ResponseEntity.ok(
                APIResponse.<FinanceSummaryDTO>builder()
                        .msg("Finance summary")
                        .data(financeService.getSummary(reportYear, reportMonth))
                        .build()
        );
    }

    @GetMapping("/host-settlements")
    public ResponseEntity<APIResponse<List<HostFinanceSettlementDTO>>> hostSettlements(
            @RequestParam int year,
            @RequestParam int month
    ) {

        return ResponseEntity.ok(
                APIResponse.<List<HostFinanceSettlementDTO>>builder()
                        .msg("Host finance settlements")
                        .data(financeService.getHostSettlementReport(year, month))
                        .build()
        );
    }

    @GetMapping("/monthly")
    public ResponseEntity<APIResponse<List<RevenueChartDTO>>> monthly(
            @RequestParam int year
    ) {

        return ResponseEntity.ok(
                APIResponse.<List<RevenueChartDTO>>builder()
                        .msg("Monthly revenue")
                        .data(financeService.getMonthlyRevenue(year))
                        .build()
        );
    }

    @GetMapping(value = "/export-pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> exportPdf(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        final LocalDate now = LocalDate.now();
        final int exportYear = year == null ? now.getYear() : year;
        final int exportMonth = month == null ? now.getMonthValue() : month;

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=finance_report_" + exportYear + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(financeService.exportFinancialPdf(exportYear, exportMonth));
    }
}
