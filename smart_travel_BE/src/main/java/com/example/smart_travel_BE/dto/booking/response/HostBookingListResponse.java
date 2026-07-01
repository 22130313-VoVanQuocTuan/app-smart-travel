package com.example.smart_travel_BE.dto.booking.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HostBookingListResponse {

    private Long id;
    private String bookingType; // HOTEL, TOUR
    private Long hotelId;
    private String hotelName;
    private String guestName;
    private String guestPhone;
    private String roomTypeName;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer numberOfRooms;
    private Integer numberOfPeople;
    private BigDecimal totalPrice;
    private BigDecimal finalPrice;
    private BigDecimal totalWithTax;
    private String status; // PENDING, CONFIRMED, CHECKED_IN, CHECKED_OUT, CANCELLED, COMPLETED
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

