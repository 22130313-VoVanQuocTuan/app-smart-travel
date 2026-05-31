package com.example.smart_travel_BE.dto.finance;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RevenueChartDTO {

    private String label;

    private BigDecimal totalRevenue;

    private BigDecimal commissionRevenue;

    private BigDecimal homestayRevenue;

    private Long bookingCount;
}