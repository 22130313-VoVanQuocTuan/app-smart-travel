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
    public ResponseEntity<APIResponse<FinanceSummaryDTO>> summary(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String groupBy,
            @RequestParam(required = false) Integer quarter
    ) {
        final FinanceSummaryDTO result;

        if (startDate != null && endDate != null) {
            result = financeService.getSummary(
                    null,
                    LocalDate.parse(startDate),
                    LocalDate.parse(endDate),
                    groupBy,
                    quarter
            );
        } else {
            result = financeService.getSummary(year, null, null, groupBy, quarter);
        }

        return ResponseEntity.ok(
                APIResponse.<FinanceSummaryDTO>builder()
                        .msg("Finance summary")
                        .data(result)
                        .build()
        );
    }

    @GetMapping("/monthly")
    public ResponseEntity<APIResponse<List<RevenueChartDTO>>> monthly(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String groupBy,
            @RequestParam(required = false) Integer quarter
    ) {
        final List<RevenueChartDTO> result;

        if (startDate != null && endDate != null) {
            result = financeService.getRevenueByDateRange(
                    LocalDate.parse(startDate),
                    LocalDate.parse(endDate)
            );
        } else {
            result = financeService.getRevenueByGroup(groupBy, year, quarter);
        }

        return ResponseEntity.ok(
                APIResponse.<List<RevenueChartDTO>>builder()
                        .msg("Monthly revenue")
                        .data(result)
                        .build()
        );
    }

    @GetMapping(value = "/export-pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> exportPdf(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String groupBy,
            @RequestParam(required = false) Integer quarter
    ) {
        final LocalDate start = startDate != null ? LocalDate.parse(startDate) : null;
        final LocalDate end = endDate != null ? LocalDate.parse(endDate) : null;
        final int exportYear = year != null ? year : (start != null ? start.getYear() : LocalDate.now().getYear());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=finance_report_" + exportYear + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(financeService.exportFinancialPdf(year, start, end, groupBy, quarter));
    }
}
