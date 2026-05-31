package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;
import com.example.smart_travel_BE.repository.BookingRepository;
import com.example.smart_travel_BE.repository.InvoiceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FinanceServiceImpl implements FinanceService {

    private final InvoiceRepository invoiceRepository;
    private final BookingRepository bookingRepository;
    private final FinancialPdfService financialPdfService;

    @Override
    public FinanceSummaryDTO getSummary() {

        return FinanceSummaryDTO.builder()
                .totalRevenue(invoiceRepository.getTotalRevenue())
                .totalCommission(invoiceRepository.getTotalCommission())
                .totalHomestayRevenue(
                        invoiceRepository.getTotalHomestayRevenue())
                .totalInvoices(invoiceRepository.count())
                .totalBookings(bookingRepository.count())
                .build();
    }

    @Override
    public List<RevenueChartDTO> getMonthlyRevenue(int year) {

        List<Object[]> data =
                invoiceRepository.getSystemRevenueByMonth(year);

        List<RevenueChartDTO> result = new ArrayList<>();

        for (Object[] row : data) {

            result.add(
                    RevenueChartDTO.builder()
                            .label("Month " + row[0])
                            .totalRevenue((BigDecimal) row[1])
                            .homestayRevenue((BigDecimal) row[2])
                            .commissionRevenue((BigDecimal) row[3])
                            .bookingCount(
                                    ((Number) row[4]).longValue())
                            .build()
            );
        }

        return result;
    }

    @Override
    public byte[] exportFinancialPdf(int year) {
        final FinanceSummaryDTO summary = getSummary();
        final List<RevenueChartDTO> monthlyRevenue = getMonthlyRevenue(year);
        return financialPdfService.generate(summary, monthlyRevenue, year);
    }
}
