package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;
import com.example.smart_travel_BE.repository.BookingRepository;
import com.example.smart_travel_BE.repository.InvoiceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
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
        return getSummary(null, null, null, null, null);
    }

    @Override
    public FinanceSummaryDTO getSummary(Integer year, LocalDate startDate, LocalDate endDate, String groupBy, Integer quarter) {
        if (startDate != null && endDate != null) {
            return getSummaryByDateRange(startDate, endDate);
        }
        if ("quarter".equalsIgnoreCase(groupBy) && year != null && quarter != null) {
            return getSummaryByQuarter(year, quarter);
        }
        if (year != null) {
            return getSummaryByYear(year);
        }
        return FinanceSummaryDTO.builder()
                .totalRevenue(invoiceRepository.getTotalRevenue())
                .totalCommission(invoiceRepository.getTotalCommission())
                .totalHomestayRevenue(invoiceRepository.getTotalHomestayRevenue())
                .totalInvoices(invoiceRepository.count())
                .totalBookings(bookingRepository.count())
                .build();
    }

    private FinanceSummaryDTO getSummaryByDateRange(LocalDate startDate, LocalDate endDate) {
        return FinanceSummaryDTO.builder()
                .totalRevenue(invoiceRepository.sumTotalAmountByDateRange(startDate, endDate))
                .totalCommission(invoiceRepository.sumCommissionAmountByDateRange(startDate, endDate))
                .totalHomestayRevenue(invoiceRepository.sumHomestayAmountByDateRange(startDate, endDate))
                .totalInvoices(invoiceRepository.countByIssueDateBetween(startDate, endDate))
                .totalBookings(invoiceRepository.countByIssueDateBetween(startDate, endDate))
                .build();
    }

    private FinanceSummaryDTO getSummaryByYear(int year) {
        return FinanceSummaryDTO.builder()
                .totalRevenue(invoiceRepository.sumTotalAmountByYear(year))
                .totalCommission(invoiceRepository.sumCommissionAmountByYear(year))
                .totalHomestayRevenue(invoiceRepository.sumHomestayAmountByYear(year))
                .totalInvoices(invoiceRepository.countByIssueDateYear(year))
                .totalBookings(invoiceRepository.countByIssueDateYear(year))
                .build();
    }

    private FinanceSummaryDTO getSummaryByQuarter(int year, int quarter) {
        final LocalDate startDate;
        final LocalDate endDate;

        switch (quarter) {
            case 1:
                startDate = LocalDate.of(year, 1, 1);
                endDate = LocalDate.of(year, 3, 31);
                break;
            case 2:
                startDate = LocalDate.of(year, 4, 1);
                endDate = LocalDate.of(year, 6, 30);
                break;
            case 3:
                startDate = LocalDate.of(year, 7, 1);
                endDate = LocalDate.of(year, 9, 30);
                break;
            default:
                startDate = LocalDate.of(year, 10, 1);
                endDate = LocalDate.of(year, 12, 31);
                break;
        }

        return getSummaryByDateRange(startDate, endDate);
    }

    @Override
    public List<RevenueChartDTO> getMonthlyRevenue(int year) {
        List<Object[]> data = invoiceRepository.getSystemRevenueByMonth(year);
        List<RevenueChartDTO> result = new ArrayList<>();

        for (Object[] row : data) {
            result.add(
                    RevenueChartDTO.builder()
                            .label("Tháng " + row[0])
                            .totalRevenue((BigDecimal) row[1])
                            .homestayRevenue((BigDecimal) row[2])
                            .commissionRevenue((BigDecimal) row[3])
                            .bookingCount(((Number) row[4]).longValue())
                            .build()
            );
        }

        return result;
    }

    @Override
    public List<RevenueChartDTO> getRevenueByDateRange(LocalDate startDate, LocalDate endDate) {
        List<Object[]> data = invoiceRepository.getSystemRevenueByDateRange(startDate, endDate);
        List<RevenueChartDTO> result = new ArrayList<>();

        for (Object[] row : data) {
            result.add(
                    RevenueChartDTO.builder()
                            .label(row[0].toString())
                            .totalRevenue((BigDecimal) row[1])
                            .homestayRevenue((BigDecimal) row[2])
                            .commissionRevenue((BigDecimal) row[3])
                            .bookingCount(((Number) row[4]).longValue())
                            .build()
            );
        }

        return result;
    }

    @Override
    public List<RevenueChartDTO> getRevenueByGroup(String groupBy, Integer year, Integer quarter) {
        if ("quarter".equalsIgnoreCase(groupBy)) {
            if (year == null) {
                year = LocalDate.now().getYear();
            }
            return getRevenueByQuarter(year);
        }

        if ("year".equalsIgnoreCase(groupBy)) {
            return getRevenueByYear();
        }

        if (year == null) {
            year = LocalDate.now().getYear();
        }
        return getMonthlyRevenue(year);
    }

    private List<RevenueChartDTO> getRevenueByQuarter(int year) {
        List<Object[]> data = invoiceRepository.getSystemRevenueByQuarter(year);
        List<RevenueChartDTO> result = new ArrayList<>();

        for (Object[] row : data) {
            result.add(
                    RevenueChartDTO.builder()
                            .label("Q" + row[0])
                            .totalRevenue((BigDecimal) row[1])
                            .homestayRevenue((BigDecimal) row[2])
                            .commissionRevenue((BigDecimal) row[3])
                            .bookingCount(((Number) row[4]).longValue())
                            .build()
            );
        }

        return result;
    }

    private List<RevenueChartDTO> getRevenueByYear() {
        List<Object[]> data = invoiceRepository.getSystemRevenueByYear();
        List<RevenueChartDTO> result = new ArrayList<>();

        for (Object[] row : data) {
            result.add(
                    RevenueChartDTO.builder()
                            .label("Năm " + row[0])
                            .totalRevenue((BigDecimal) row[1])
                            .homestayRevenue((BigDecimal) row[2])
                            .commissionRevenue((BigDecimal) row[3])
                            .bookingCount(((Number) row[4]).longValue())
                            .build()
            );
        }

        return result;
    }

    @Override
    public byte[] exportFinancialPdf(int year) {
        final FinanceSummaryDTO summary = getSummary(year, null, null, null, null);
        final List<RevenueChartDTO> monthlyRevenue = getMonthlyRevenue(year);
        return financialPdfService.generate(summary, monthlyRevenue, year);
    }

    @Override
    public byte[] exportFinancialPdf(Integer year, LocalDate startDate, LocalDate endDate, String groupBy, Integer quarter) {
        final FinanceSummaryDTO summary = getSummary(year, startDate, endDate, groupBy, quarter);
        final List<RevenueChartDTO> monthlyRevenue;
        if (startDate != null && endDate != null) {
            monthlyRevenue = getRevenueByDateRange(startDate, endDate);
        } else {
            monthlyRevenue = getRevenueByGroup(groupBy, year, quarter);
        }

        final int outputYear = year != null ? year : (startDate != null ? startDate.getYear() : LocalDate.now().getYear());
        return financialPdfService.generate(summary, monthlyRevenue, outputYear);
    }
}
