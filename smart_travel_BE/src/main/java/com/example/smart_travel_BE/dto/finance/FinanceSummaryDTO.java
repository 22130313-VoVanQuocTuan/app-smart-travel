package com.example.smart_travel_BE.dto.finance;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceSummaryDTO {

    private BigDecimal totalRevenue;

    private BigDecimal totalCommission;

    private BigDecimal totalHomestayRevenue;

    private Long totalInvoices;

    private Long totalBookings;
}