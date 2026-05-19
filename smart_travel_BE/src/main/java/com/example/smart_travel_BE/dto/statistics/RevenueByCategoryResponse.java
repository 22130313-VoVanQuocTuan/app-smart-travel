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
public class RevenueByCategoryResponse {
    private int year;
    private int month;
    private BigDecimal totalRevenue;
    private List<CategoryRevenueItem> categories;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryRevenueItem {
        private Long homestayId;
        private String homestayName;
        private BigDecimal revenue;
        private long invoiceCount;
        private double percentage;
    }
}
