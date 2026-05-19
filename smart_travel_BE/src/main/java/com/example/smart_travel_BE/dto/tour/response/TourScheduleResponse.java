package com.example.smart_travel_BE.dto.tour.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TourScheduleResponse {
    private Long id;
    private Integer dayNumber;
    private String title;
    private String activities;
    private String accommodation;
    private List<String> meals;
}
