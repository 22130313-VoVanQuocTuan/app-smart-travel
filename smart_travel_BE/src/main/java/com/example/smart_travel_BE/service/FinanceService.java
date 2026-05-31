package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;

import java.util.List;

public interface FinanceService {

    FinanceSummaryDTO getSummary();

    List<RevenueChartDTO> getMonthlyRevenue(int year);

    byte[] exportFinancialPdf(int year);
}