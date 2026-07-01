package com.example.smart_travel_BE.dto.finance;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceSummaryDTO {

    private Integer reportYear;

    private Integer reportMonth;

    private BigDecimal totalRevenue;

    private BigDecimal totalCommission;

    private BigDecimal totalHomestayRevenue;

    private BigDecimal monthlyCompletedRevenue;

    private BigDecimal monthlyOnlineRevenue;

    private BigDecimal monthlyCashRevenue;

    private BigDecimal monthlyHostPayoutAmount;

    private BigDecimal monthlyCashCommissionReceivable;

    private Long totalInvoices;

    private Long totalBookings;
}
