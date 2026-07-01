package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.HostFinanceSettlementDTO;
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
    public FinanceSummaryDTO getSummary(int year, int month) {
        final List<HostFinanceSettlementDTO> hostReports =
                getHostSettlementReport(year, month);

        BigDecimal monthlyCompletedRevenue = BigDecimal.ZERO;
        BigDecimal monthlyOnlineRevenue = BigDecimal.ZERO;
        BigDecimal monthlyCashRevenue = BigDecimal.ZERO;
        BigDecimal monthlyHostPayoutAmount = BigDecimal.ZERO;
        BigDecimal monthlyCashCommissionReceivable = BigDecimal.ZERO;

        for (HostFinanceSettlementDTO report : hostReports) {
            monthlyCompletedRevenue =
                    monthlyCompletedRevenue.add(nullSafe(report.getTotalCompletedRevenue()));
            monthlyOnlineRevenue =
                    monthlyOnlineRevenue.add(nullSafe(report.getOnlineCompletedRevenue()));
            monthlyCashRevenue =
                    monthlyCashRevenue.add(nullSafe(report.getCashCompletedRevenue()));
            monthlyHostPayoutAmount =
                    monthlyHostPayoutAmount.add(nullSafe(report.getAmountPayableToHost()));
            monthlyCashCommissionReceivable =
                    monthlyCashCommissionReceivable.add(nullSafe(report.getAmountHostMustTransfer()));
        }

        return FinanceSummaryDTO.builder()
                .reportYear(year)
                .reportMonth(month)
                .totalRevenue(invoiceRepository.getTotalRevenue())
                .totalCommission(invoiceRepository.getTotalCommission())
                .totalHomestayRevenue(
                        invoiceRepository.getTotalHomestayRevenue())
                .monthlyCompletedRevenue(monthlyCompletedRevenue)
                .monthlyOnlineRevenue(monthlyOnlineRevenue)
                .monthlyCashRevenue(monthlyCashRevenue)
                .monthlyHostPayoutAmount(monthlyHostPayoutAmount)
                .monthlyCashCommissionReceivable(monthlyCashCommissionReceivable)
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
    public List<HostFinanceSettlementDTO> getHostSettlementReport(int year, int month) {

        List<Object[]> rows = invoiceRepository.getHostFinanceSettlementReport(year, month);
        List<HostFinanceSettlementDTO> result = new ArrayList<>();

        for (Object[] row : rows) {
            result.add(
                    HostFinanceSettlementDTO.builder()
                            .hostId(((Number) row[0]).longValue())
                            .hostName((String) row[1])
                            .totalCompletedBookings(((Number) row[2]).longValue())
                            .onlineCompletedBookings(((Number) row[3]).longValue())
                            .cashCompletedBookings(((Number) row[4]).longValue())
                            .totalCompletedRevenue((BigDecimal) row[5])
                            .onlineCompletedRevenue((BigDecimal) row[6])
                            .cashCompletedRevenue((BigDecimal) row[7])
                            .amountPayableToHost((BigDecimal) row[8])
                            .amountHostMustTransfer((BigDecimal) row[9])
                            .totalCommission((BigDecimal) row[10])
                            .homestayCount(((Number) row[11]).longValue())
                            .build()
            );
        }

        return result;
    }

    @Override
    public byte[] exportFinancialPdf(int year, int month) {
        final FinanceSummaryDTO summary = getSummary(year, month);
        final List<RevenueChartDTO> monthlyRevenue = getMonthlyRevenue(year);
        return financialPdfService.generate(summary, monthlyRevenue, year);
    }

    private BigDecimal nullSafe(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }
}
