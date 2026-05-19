package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.BookingTour;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookingTourRepository extends JpaRepository<BookingTour, Long> {
}