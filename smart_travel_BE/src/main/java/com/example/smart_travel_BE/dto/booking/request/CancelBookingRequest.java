package com.example.smart_travel_BE.dto.booking.request;

import lombok.Data;

@Data
public class CancelBookingRequest {
    private String reason;
}