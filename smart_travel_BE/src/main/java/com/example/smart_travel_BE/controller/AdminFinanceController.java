package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
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
    public ResponseEntity<APIResponse<FinanceSummaryDTO>> summary() {

        return ResponseEntity.ok(
                APIResponse.<FinanceSummaryDTO>builder()
                        .msg("Finance summary")
                        .data(financeService.getSummary())
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
            @RequestParam(required = false) Integer year
    ) {
        final int exportYear = year == null ? LocalDate.now().getYear() : year;

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=finance_report_" + exportYear + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(financeService.exportFinancialPdf(exportYear));
    }
}
