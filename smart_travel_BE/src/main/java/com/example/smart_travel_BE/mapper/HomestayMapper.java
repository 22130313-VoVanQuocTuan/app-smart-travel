package com.example.smart_travel_BE.mapper;

import com.example.smart_travel_BE.dto.homestay.response.HomestayDetailResponse;
import com.example.smart_travel_BE.entity.Homestay;
import com.example.smart_travel_BE.entity.HomestayImage;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Collections;
import java.util.List;

public interface HomestayMapper {

    /**
     * Chuyển đổi từ Entity Hotel sang DTO HotelResponse
     */
    public static HomestayDetailResponse toDetailResponse(Homestay homestay) {
        if (homestay == null) return null;

        return HomestayDetailResponse.builder()
                .id(homestay.getId())
                .name(homestay.getName())
                .address(homestay.getAddress())
                .stars(homestay.getStarRating())
                .rating(homestay.getAverageRating() != null ? homestay.getAverageRating().doubleValue() : 0.0)
                .numOfReviews(homestay.getReviewCount())
                .description(homestay.getDescription())
                .thumbnail(homestay.getThumbnail())
                .images(
                        homestay.getImages() != null
                                ? homestay.getImages().stream().map(HomestayImage::getImageUrl).toList()
                                : null
                )
                .destinationName(
                        homestay.getDestination() != null
                                ? homestay.getDestination().getName()
                                : null
                )
                .provinceName(
                        homestay.getDestination() != null && homestay.getDestination().getProvince() != null
                                ? homestay.getDestination().getProvince().getName()
                                : null
                )
                .rooms(
                        homestay.getRoomTypes() != null
                                ? homestay.getRoomTypes().stream()
                                .map(RoomTypeMapper::toResponse)
                                .toList()
                                : null
                )
                .latitude(homestay.getLatitude())
                .longitude(homestay.getLongitude())
                .amenities(parseAmenities(homestay.getAmenities()))
                .build();
    }

    private static List<String> parseAmenities(String amenitiesJson) {
        if (amenitiesJson == null || amenitiesJson.isBlank()) {
            return Collections.emptyList();
        }

        try {
            return new ObjectMapper().readValue(amenitiesJson, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return Collections.singletonList(amenitiesJson);
        }
    }
}
