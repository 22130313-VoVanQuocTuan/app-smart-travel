package com.example.smart_travel_BE.dto.booking.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BookingResponse {

    private Long id;
    private String bookingType;
    private Long hotelId;
    private String hotelName;
    private Long roomTypeId;
    private String roomTypeName;
    private LocalDate startDate;
    private LocalDate endDate;
    private Long nights;
    private Integer numberOfPeople;
    private Integer numberOfRooms;

    // Thông tin tour đi kèm
    private List<TourBookingInfo> tours;

    // Thông tin giá
    private BigDecimal hotelPrice;
    private BigDecimal totalTourPrice;
    private BigDecimal totalPrice;
    private BigDecimal discountAmount;
    private String couponCode;
    private BigDecimal finalPrice;
    private BigDecimal taxRate;
    private BigDecimal taxAmount;
    private BigDecimal totalWithTax;

    // Trạng thái
    private String status;
    private String message;
    private LocalDateTime createdAt;
    private  String cancellationReason;
    private String paymentStatus;
    private String paymentMethod;
    private String customerName;
    private String customerPhone;
    private String customerEmail;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TourBookingInfo {
        private Long tourId;
        private String tourName;
        private LocalDate tourDate;
        private Integer numberOfPeople;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;
        private String status;
    }

    // Constructor cho response đơn giản
    public BookingResponse(Long id, BigDecimal finalPrice, String message) {
        this.id = id;
        this.finalPrice = finalPrice;
        this.message = message;
        this.createdAt = LocalDateTime.now();
    }

    // Constructor đầy đủ cho homestay + tours
    public BookingResponse(Long id, String bookingType, Long hotelId, String hotelName,
                           Long roomTypeId, String roomTypeName, LocalDate startDate,
                           LocalDate endDate, Long nights, Integer numberOfPeople,
                           Integer numberOfRooms, List<TourBookingInfo> tours,
                           BigDecimal hotelPrice, BigDecimal totalTourPrice,
                           BigDecimal totalPrice, BigDecimal discountAmount,
                           String couponCode, BigDecimal finalPrice, String status,
                           String message, String cancellationReason) {
        this.id = id;
        this.bookingType = bookingType;
        this.hotelId = hotelId;
        this.hotelName = hotelName;
        this.roomTypeId = roomTypeId;
        this.roomTypeName = roomTypeName;
        this.startDate = startDate;
        this.endDate = endDate;
        this.nights = nights;
        this.numberOfPeople = numberOfPeople;
        this.numberOfRooms = numberOfRooms;
        this.tours = tours;
        this.hotelPrice = hotelPrice;
        this.totalTourPrice = totalTourPrice;
        this.totalPrice = totalPrice;
        this.discountAmount = discountAmount;
        this.couponCode = couponCode;
        this.finalPrice = finalPrice;
        this.status = status;
        this.message = message;
        this.createdAt = LocalDateTime.now();
        this.cancellationReason = cancellationReason;
    }
}
