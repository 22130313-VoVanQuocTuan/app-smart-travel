package com.example.smart_travel_BE.dto.tour.request;

import lombok.Data;

import java.util.List;

@Data
public class TourScheduleRequest {
    private Integer dayNumber;
    private String title;
    private String activities;
    private String accommodation;
    private List<String> meals;
}
