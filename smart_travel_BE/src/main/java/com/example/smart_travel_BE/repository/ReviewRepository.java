package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    // Tìm review của user cho hotel
    @Query("SELECT r FROM Review r WHERE r.user.id = :userId AND r.hotelId = :hotelId")
    Optional<Review> findByUserIdAndHotelId(@Param("userId") Long userId, @Param("hotelId") Long hotelId);

    // Lấy tất cả reviews cho hotel (chỉ approved)
    @Query("SELECT r FROM Review r WHERE r.hotelId = :hotelId AND r.isApproved = true ORDER BY r.createdAt DESC")
    List<Review> findApprovedReviewsByHotelId(@Param("hotelId") Long hotelId);

    // Lấy tất cả reviews cho hotel (với pagination)
    @Query("SELECT r FROM Review r WHERE r.hotelId = :hotelId AND r.isApproved = true ORDER BY r.likesCount DESC, r.createdAt DESC")
    List<Review> findApprovedReviewsByHotelIdSortedByLikes(@Param("hotelId") Long hotelId);

    // Đếm số review cho hotel
    @Query("SELECT COUNT(r) FROM Review r WHERE r.hotelId = :hotelId AND r.isApproved = true")
    long countApprovedReviewsByHotelId(@Param("hotelId") Long hotelId);

    // Tính rating trung bình cho hotel
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.hotelId = :hotelId AND r.isApproved = true")
    Double getAverageRatingByHotelId(@Param("hotelId") Long hotelId);

    // Lấy reviews theo rating
    @Query("SELECT r FROM Review r WHERE r.hotelId = :hotelId AND r.rating = :rating AND r.isApproved = true ORDER BY r.createdAt DESC")
    List<Review> findByHotelIdAndRating(@Param("hotelId") Long hotelId, @Param("rating") Integer rating);

    // Tìm reviews chưa duyệt
    @Query("SELECT r FROM Review r WHERE r.isApproved = false ORDER BY r.createdAt ASC")
    List<Review> findPendingReviews();
}

