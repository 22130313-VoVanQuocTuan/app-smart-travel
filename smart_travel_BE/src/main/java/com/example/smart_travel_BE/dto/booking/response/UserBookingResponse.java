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
public class UserBookingResponse {
    private Long id;
    private String bookingType;
    private Long hotelId;
    private String hotelName;
    private String roomTypeName;
    private LocalDate startDate;
    private LocalDate endDate;
    private Long nights;
    private Integer numberOfPeople;
    private Integer numberOfRooms;
    private BigDecimal totalPrice;
    private BigDecimal discountAmount;
    private BigDecimal finalPrice;
    private BigDecimal taxRate;
    private BigDecimal taxAmount;
    private BigDecimal totalWithTax;
    private String status;
    private String cancellationReason;
    private String paymentStatus;
    private String paymentMethod;
    private String hotelAddress;
    private String hotelPhone;
    private String qrCode;
    private LocalDateTime createdAt;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
}
