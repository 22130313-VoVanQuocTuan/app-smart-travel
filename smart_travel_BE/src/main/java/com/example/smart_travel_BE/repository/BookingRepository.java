package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.Booking;
import com.example.smart_travel_BE.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {
    Optional<Booking> findFirstByUser(User user);
    
    void deleteByUser(User user);
    
    // Host booking management queries
    @Query("SELECT b FROM Booking b WHERE b.hotelId = :hotelId ORDER BY b.startDate DESC")
    List<Booking> findByHotelIdOrderByStartDateDesc(@Param("hotelId") Long hotelId);
    
    @Query("SELECT b FROM Booking b WHERE b.hotelId = :hotelId AND b.startDate >= :startDate AND b.startDate <= :endDate ORDER BY b.startDate ASC")
    List<Booking> findByHotelIdAndDateRange(@Param("hotelId") Long hotelId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT b FROM Booking b WHERE b.hotelId = :hotelId AND b.status = :status ORDER BY b.startDate DESC")
    List<Booking> findByHotelIdAndStatus(@Param("hotelId") Long hotelId, @Param("status") String status);
    
    @Query("SELECT COUNT(b) FROM Booking b WHERE b.hotelId = :hotelId AND b.status = :status")
    long countByHotelIdAndStatus(@Param("hotelId") Long hotelId, @Param("status") String status);

    List<Booking> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Query("""
            SELECT b
            FROM Booking b
            LEFT JOIN FETCH b.roomType rt
            WHERE b.user.id = :userId
            ORDER BY b.createdAt DESC
            """)
    List<Booking> findUserBookingsWithRoomTypeByUserId(@Param("userId") Long userId);

    List<Booking> findByUserIdAndEndDateGreaterThanEqualAndStatusNot(
            Long userId, LocalDate date, String excludeStatus
    );

    @Query("""
            SELECT b
            FROM Booking b
            LEFT JOIN FETCH b.roomType rt
            WHERE b.user.id = :userId
              AND b.endDate >= :date
              AND b.status <> :excludeStatus
            ORDER BY b.createdAt DESC
            """)
    List<Booking> findCurrentBookingsWithRoomType(
            @Param("userId") Long userId,
            @Param("date") LocalDate date,
            @Param("excludeStatus") String excludeStatus
    );

    List<Booking> findByUserIdAndStatusInOrderByCreatedAtDesc(
            Long userId, List<String> statuses
    );

    @Query("""
            SELECT b
            FROM Booking b
            LEFT JOIN FETCH b.roomType rt
            WHERE b.user.id = :userId
              AND b.status IN :statuses
            ORDER BY b.createdAt DESC
            """)
    List<Booking> findBookingHistoryWithRoomType(
            @Param("userId") Long userId,
            @Param("statuses") List<String> statuses
    );

}
