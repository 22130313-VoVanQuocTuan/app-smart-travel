package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.Destination;
import com.example.smart_travel_BE.entity.Homestay;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal; // <--- QUAN TRỌNG: Thêm import này
import java.util.List;

@Repository
public interface HomestayRepository extends JpaRepository<Homestay, Long>, JpaSpecificationExecutor<Homestay> {

    @Query("SELECT h FROM Homestay h WHERE LOWER(h.name) LIKE LOWER(CONCAT('%', :name, '%')) AND h.isActive = true")
    List<Homestay> findByNameContainingIgnoreCase(@Param("name") String name);

    @Query("SELECT h FROM Homestay h WHERE h.destination = :destination AND h.isActive = true")
    List<Homestay> findByDestination(@Param("destination") Destination destination);

    @Query("SELECT h FROM Homestay h " +
            "WHERE (LOWER(h.name) LIKE LOWER(CONCAT('%', :hotelName, '%')) " +
            "OR LOWER(h.destination.name) LIKE LOWER(CONCAT('%', :destName, '%'))) " +
            "AND h.isActive = true")
    List<Homestay> findByNameContainingIgnoreCaseOrDestination_NameContainingIgnoreCase(@Param("hotelName") String hotelName, @Param("destName") String destName);

    @Query("SELECT h FROM Homestay h " +
            "WHERE (LOWER(h.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(h.destination.name) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND h.isActive = true")
    List<Homestay> searchByKeyword(@Param("keyword") String keyword);

    List<Homestay> findTop5ByOrderByPricePerNightAsc();

    List<Homestay> findByPricePerNightBetween(BigDecimal min, BigDecimal max);

    List<Homestay> findByDestinationOrderByPricePerNightAsc(Destination destination);


    List<Homestay> findByOwnerIdAndIsActiveTrue(Long ownerId);
    long countByOwnerIdAndIsActiveTrue(Long ownerId);
    List<Homestay> findByDestinationIdAndIsActiveTrue(Long destinationId);
    List<Homestay> findByPricePerNightBetweenAndIsActiveTrue(BigDecimal minPrice, BigDecimal maxPrice);
    Page<Homestay> findTopByOrderByAverageRatingDesc(Pageable pageable);
}