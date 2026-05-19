// dto/tour/request/TourCreateRequest.java
package com.example.smart_travel_BE.dto.tour.request;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;

@Data
public class TourCreateRequest {
    private String name;
    private String description;
    private Integer durationDays;
    private Integer durationNights;
    private BigDecimal pricePerPerson;
    private Integer maxPeople;
    private Integer minPeople = 1;
    private List<String> included;
    private List<String> excluded;
    private Long homestayId;
    private List<TourScheduleRequest> schedules;
    private MultipartFile thumbnail;
    private List<MultipartFile> images;
    private Boolean syncGalleryImages;
    private List<String> keepImageUrls;

}

