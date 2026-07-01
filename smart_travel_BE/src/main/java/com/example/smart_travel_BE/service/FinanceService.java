package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.HostFinanceSettlementDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;

import java.util.List;

public interface FinanceService {

    FinanceSummaryDTO getSummary(int year, int month);

    List<RevenueChartDTO> getMonthlyRevenue(int year);

    List<HostFinanceSettlementDTO> getHostSettlementReport(int year, int month);

    byte[] exportFinancialPdf(int year, int month);
}
