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
public class DashboardStatsResponse {
    private int totalUsers;
    private int totalUsersByRoleUSER;
    private int totalUsersByRoleHOST;
    private int totalUsersByRoleADMIN;
    private int totalProvinces;
    private int totalDestinations;
    private int totalHotels;
    private int totalTours;
    private int totalVouchers;
    private int todayInvoices;
    private BigDecimal todayRevenue;
    private BigDecimal totalRevenue;
    private List<TopDestinationDTO> topDestinations;

    private List<TopHomestayDTO> topHomestays;
    private List<TopHostDTO> topHosts;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TopDestinationDTO {
        private Long id;
        private String name;
        private long viewCount;
        private String provinceName;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TopHomestayDTO {
        private Long id;
        private String name;
        private String hostName;
        private BigDecimal totalRevenue;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TopHostDTO {
        private Long id;
        private String name;
        private BigDecimal totalRevenue;
    }
}
