package com.example.smart_travel_BE.dto.homestay.response;

import com.example.smart_travel_BE.dto.tour.response.TourScheduleResponse;
import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class TourBriefResponse {
    private Long id;
    private String name;
    private String description;
    private Integer durationDays;
    private Integer durationNights;
    private BigDecimal pricePerPerson;
    private Integer maxPeople;
    private Integer minPeople;
    private Double averageRating;
    private Integer reviewCount;
    private String thumbnail;
    private List<String> images;
    private List<String> included;
    private List<String> excluded;
    private List<TourScheduleResponse> schedules;
}