package com.example.smart_travel_BE.dto.booking.request;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Data
public class BookingRequest {
    private String bookingType; // Chỉ còn "HOTEL"
    private Long hotelId;
    private Long roomTypeId;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer numberOfPeople;
    private Integer numberOfRooms;
    private String specialRequests;
    private String couponCode;

    // Danh sách tour đi kèm (có thể null hoặc rỗng)
    private List<TourBookingItem> tours;

    @Data
    public static class TourBookingItem {
        private Long tourId;
        private LocalDate tourDate;
        private Integer numberOfPeople;
    }
}