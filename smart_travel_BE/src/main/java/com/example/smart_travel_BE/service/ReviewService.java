package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.review.request.CreateReviewRequest;
import com.example.smart_travel_BE.dto.review.response.ReviewResponse;
import com.example.smart_travel_BE.entity.Booking;
import com.example.smart_travel_BE.entity.Review;
import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.BookingRepository;
import com.example.smart_travel_BE.repository.ReviewRepository;
import com.example.smart_travel_BE.repository.UserProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final UserProfileRepository userProfileRepository;

    /**
     * Tạo review mới cho booking
     */
    public ReviewResponse createReview(CreateReviewRequest request, User user) {
        try {
            // Kiểm tra booking tồn tại và đã completed
            Booking booking = bookingRepository.findById(request.getBookingId())
                    .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

            if (!booking.getUser().getId().equals(user.getId())) {
                throw new AppException(ErrorCode.UNAUTHORIZED);
            }

            if (!"COMPLETED".equals(booking.getStatus())) {
                throw new AppException(ErrorCode.BOOKING_NOT_COMPLETED);
            }

            // Kiểm tra user đã review hotel này chưa
            if (reviewRepository.findByUserIdAndHotelId(user.getId(), booking.getHotelId()).isPresent()) {
                throw new AppException(ErrorCode.REVIEW_ALREADY_EXISTS);
            }

            // Tạo review mới
            Review review = Review.builder()
                    .user(user)
                    .hotelId(booking.getHotelId())
                    .rating(request.getRating())
                    .comment(request.getComment())
                    .likesCount(0)
                    .isApproved(true) // Admin phải duyệt trước
                    .build();

            Review savedReview = reviewRepository.save(review);
            log.info("Review created successfully. ReviewId: {}, HotelId: {}", savedReview.getId(), booking.getHotelId());

            return mapToResponse(savedReview);
        } catch (AppException e) {
            throw e;
        } catch (Exception e) {
            log.error("Error creating review", e);
            throw new AppException(ErrorCode.REVIEW_CREATE_FAILED);
        }
    }

    /**
     * Lấy reviews được duyệt cho hotel
     */
    public List<ReviewResponse> getReviewsByHotelId(Long hotelId) {
        List<Review> reviews = reviewRepository.findApprovedReviewsByHotelIdSortedByLikes(hotelId);
        return reviews.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    /**
     * Lấy reviews theo rating
     */
    public List<ReviewResponse> getReviewsByHotelIdAndRating(Long hotelId, Integer rating) {
        if (rating < 1 || rating > 5) {
            throw new AppException(ErrorCode.INVALID_RATING);
        }
        List<Review> reviews = reviewRepository.findByHotelIdAndRating(hotelId, rating);
        return reviews.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    /**
     * Lấy rating trung bình
     */
    public Double getAverageRating(Long hotelId) {
        Double avg = reviewRepository.getAverageRatingByHotelId(hotelId);
        return avg != null ? avg : 0.0;
    }

    /**
     * Đếm số review
     */
    public long getReviewCount(Long hotelId) {
        return reviewRepository.countApprovedReviewsByHotelId(hotelId);
    }

    /**
     * Check xem user đã review hotel này chưa
     */
    public boolean hasUserReviewedHotel(Long userId, Long hotelId) {
        return reviewRepository.findByUserIdAndHotelId(userId, hotelId).isPresent();
    }

    /**
     * Phê duyệt review (admin)
     */
    public ReviewResponse approveReview(Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new AppException(ErrorCode.REVIEW_NOT_FOUND));

        review.setIsApproved(true);
        Review savedReview = reviewRepository.save(review);
        log.info("Review approved. ReviewId: {}", reviewId);

        return mapToResponse(savedReview);
    }

    /**
     * Reject review (admin)
     */
    public void rejectReview(Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new AppException(ErrorCode.REVIEW_NOT_FOUND));

        reviewRepository.delete(review);
        log.info("Review rejected and deleted. ReviewId: {}", reviewId);
    }

    /**
     * Like review
     */
    public ReviewResponse likeReview(Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new AppException(ErrorCode.REVIEW_NOT_FOUND));

        review.setLikesCount(review.getLikesCount() + 1);
        Review savedReview = reviewRepository.save(review);

        return mapToResponse(savedReview);
    }

    /**
     * Mapper: Review -> ReviewResponse
     */
    private ReviewResponse mapToResponse(Review review) {
        String userFullName = "Unknown";
        String userAvatar = null;
        
        if (review.getUser() != null ) {
            userFullName = review.getUser().getFullName() != null
                    ? review.getUser().getFullName()
                    : "Unknown";
            userAvatar = userProfileRepository.findByUserId(review.getUser().getId())
                    .map(profile -> profile.getAvatarUrl())
                    .orElse(null);
        }

        return ReviewResponse.builder()
                .id(review.getId())
                .userId(review.getUser().getId())
                .userFullName(userFullName)
                .userAvatar(userAvatar)
                .hotelId(review.getHotelId())
                .rating(review.getRating())
                .comment(review.getComment())
                .likesCount(review.getLikesCount())
                .isApproved(review.getIsApproved())
                .createdAt(review.getCreatedAt())
                .build();
    }
}

