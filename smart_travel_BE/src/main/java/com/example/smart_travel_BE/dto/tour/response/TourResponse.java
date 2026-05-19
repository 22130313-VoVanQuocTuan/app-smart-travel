package com.example.smart_travel_BE.dto.tour.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class TourResponse {
    private Long id;
    private String name;
    private String description;
    private Integer durationDays;
    private Integer durationNights;
    private BigDecimal pricePerPerson;
    private Integer maxPeople;
    private Integer minPeople;
    private String thumbnail;
    private List<String> images;
    private List<String> included;
    private List<String> excluded;
    private List<TourScheduleResponse> schedules;
    private Long homestayId;
    private String homestayName;
    private Double averageRating;
    private Integer reviewCount;
    private Integer bookingCount;
    private Boolean isActive;

    @Data
    @Builder
    public static class TourScheduleResponse {
        private Integer dayNumber;
        private String title;
        private String activities;
        private String accommodation;
        private List<String> meals;
    }
}