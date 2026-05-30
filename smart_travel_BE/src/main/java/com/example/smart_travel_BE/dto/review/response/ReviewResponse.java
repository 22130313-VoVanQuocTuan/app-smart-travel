package com.example.smart_travel_BE.dto.review.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewResponse {
    private Long id;
    private Long userId;
    private String userFullName;
    private String userAvatar;
    private Long hotelId;
    private Integer rating;
    private String comment;
    private Integer likesCount;
    private Boolean isApproved;
    private LocalDateTime createdAt;
}


