package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;

import java.time.LocalDate;
import java.util.List;

public interface FinanceService {

    FinanceSummaryDTO getSummary();

    FinanceSummaryDTO getSummary(Integer year, LocalDate startDate, LocalDate endDate, String groupBy, Integer quarter);

    List<RevenueChartDTO> getMonthlyRevenue(int year);

    List<RevenueChartDTO> getRevenueByDateRange(LocalDate startDate, LocalDate endDate);

    List<RevenueChartDTO> getRevenueByGroup(String groupBy, Integer year, Integer quarter);

    byte[] exportFinancialPdf(int year);

    byte[] exportFinancialPdf(Integer year, LocalDate startDate, LocalDate endDate, String groupBy, Integer quarter);
}