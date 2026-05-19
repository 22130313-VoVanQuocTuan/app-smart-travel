package com.example.smart_travel_BE.dto.statistics;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RevenueResponse {
    private String type; // "DAY", "MONTH", "YEAR", "RANGE"
    private BigDecimal totalRevenue;
    private List<RevenueDataPoint> dataPoints;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RevenueDataPoint {
        private String label;
        private BigDecimal revenue;
        private BigDecimal homestayAmount;
        private BigDecimal commissionAmount;
        private long invoiceCount;
    }
}
