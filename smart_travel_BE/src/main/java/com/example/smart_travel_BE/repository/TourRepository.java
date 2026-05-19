package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.Destination;
import com.example.smart_travel_BE.entity.Tour;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal; // <--- QUAN TRỌNG: Thêm import này
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface TourRepository extends JpaRepository<Tour, Long>, JpaSpecificationExecutor<Tour> {
    // Tìm tất cả tour đang hoạt động
    List<Tour> findByIsActiveTrue();

    // Tìm tour active theo destination
    @Query("""
    SELECT t FROM Tour t
    WHERE t.isActive = true
    AND t.homestay.id = :homestayId
""")
    List<Tour> findActiveToursByHomestay(
            @Param("homestayId") Long homestayId);

    @Override
    @EntityGraph(attributePaths = {"images", "destination"})
    Page<Tour> findAll(Specification<Tour> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"destination"})
    Optional<Tour> findWithDetailById(Long id);
    List<Tour> findByHomestayIdAndIsActiveTrue(Long homestayId);

}