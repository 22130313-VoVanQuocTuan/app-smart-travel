package com.example.smart_travel_BE.dto.homestay.request;

import lombok.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HomestayCreateRequest {

    private String name;
    private String address;
    private Integer stars;
    private String description;

    private Double latitude;
    private Double longitude;

    private Long destinationId;
    private String phone;
    private String email;
    private List<String> amenities;
    private Integer totalRooms;
    private Integer availableRooms;

    private List<RoomTypeCreateRequest> roomTypes;
    private MultipartFile thumbnail;
    private List<MultipartFile> images;
    private List<String> keepImageUrls;
    private Boolean syncGalleryImages;
}
