package com.example.smart_travel_BE.dto.user.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
public class PaymentRequest {

    // Thông tin homestay
    @NotNull(message = "homestayId không được để trống")
    private Long homestayId;

    private Long roomTypeId;

    @NotNull(message = "startDate không được để trống")
    private LocalDate startDate;

    @NotNull(message = "endDate không được để trống")
    private LocalDate endDate;

    @NotNull(message = "numberOfPeople không được để trống")
    private Integer numberOfPeople;

    @NotNull(message = "numberOfRooms không được để trống")
    private Integer numberOfRooms;

    private String couponCode;
    private BigDecimal discountAmount;

    @NotEmpty(message = "paymentMethod không được để trống")
    private String paymentMethod;

    @NotNull(message = "userId không được để trống")
    private Long userId;

    private List<TourBookingRequest> tours;

    @Data
    public static class TourBookingRequest {
        private Long tourId;
        private String tourName;
        private BigDecimal pricePerPerson;
        private LocalDate tourDate;
        private Integer numberOfPeople;
    }
}