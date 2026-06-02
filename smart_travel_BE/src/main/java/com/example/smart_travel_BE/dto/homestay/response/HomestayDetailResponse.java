package com.example.smart_travel_BE.dto.homestay.response;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HomestayDetailResponse {
    private Long id;
    private String name;
    private Long ownerId;
    private String ownerName;
    private String address;
    private Integer stars;
    private Double rating;
    private Integer numOfReviews;
    private String description;
    private String thumbnail;
    private List<String> images;
    private String destinationName;
    private String phone;
    private String email;
    private Long destinationId;
    private List<String> amenities;
    private String provinceName;
    private List<RoomTypeResponse> rooms;
    private Double minPrice;
    private Double latitude;
    private Double longitude;
    private BigDecimal pricePerNight;

    // Danh sách tour có thể đặt kèm
    private List<TourBriefResponse> availableTours;
}