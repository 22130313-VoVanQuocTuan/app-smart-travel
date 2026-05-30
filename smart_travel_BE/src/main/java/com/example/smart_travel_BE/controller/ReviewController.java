package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.review.request.CreateReviewRequest;
import com.example.smart_travel_BE.dto.review.response.ReviewResponse;
import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.service.ReviewService;
import com.example.smart_travel_BE.util.SecurityUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;
    private final SecurityUtil securityUtil;

    @PostMapping("/create")
    @PreAuthorize("hasAnyRole('USER', 'HOST')")
    public ResponseEntity<?> createReview(@Valid @RequestBody CreateReviewRequest request) {
        try {
            User currentUser = securityUtil.getUserDetail();
            ReviewResponse response = reviewService.createReview(request, currentUser);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (AppException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Tạo review thất bại: " + e.getMessage()));
        }
    }

    @GetMapping("/hotel/{hotelId}")
    public ResponseEntity<?> getHotelReviews(@PathVariable Long hotelId) {
        try {
            List<ReviewResponse> reviews = reviewService.getReviewsByHotelId(hotelId);
            return ResponseEntity.ok(reviews);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Lỗi khi lấy reviews: " + e.getMessage()));
        }
    }

    @GetMapping("/hotel/{hotelId}/rating/{rating}")
    public ResponseEntity<?> getHotelReviewsByRating(
            @PathVariable Long hotelId,
            @PathVariable Integer rating) {
        try {
            List<ReviewResponse> reviews = reviewService.getReviewsByHotelIdAndRating(hotelId, rating);
            return ResponseEntity.ok(reviews);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Lỗi: " + e.getMessage()));
        }
    }

    @GetMapping("/check/{hotelId}")
    @PreAuthorize("hasAnyRole('USER', 'HOST')")
    public ResponseEntity<?> checkIfUserReviewedHotel(@PathVariable Long hotelId) {
        try {
            User currentUser = securityUtil.getUserDetail();
            boolean hasReviewed = reviewService.hasUserReviewedHotel(currentUser.getId(), hotelId);
            Map<String, Object> response = new HashMap<>();
            response.put("hasReviewed", hasReviewed);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/hotel/{hotelId}/average")
    public ResponseEntity<?> getAverageRating(@PathVariable Long hotelId) {
        try {
            Double avgRating = reviewService.getAverageRating(hotelId);
            long count = reviewService.getReviewCount(hotelId);
            Map<String, Object> response = new HashMap<>();
            response.put("averageRating", avgRating);
            response.put("reviewCount", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Lỗi: " + e.getMessage()));
        }
    }

    @PutMapping("/{reviewId}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> approveReview(@PathVariable Long reviewId) {
        try {
            ReviewResponse response = reviewService.approveReview(reviewId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{reviewId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> rejectReview(@PathVariable Long reviewId) {
        try {
            reviewService.rejectReview(reviewId);
            return ResponseEntity.ok(Map.of("message", "Review đã bị xóa"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}


