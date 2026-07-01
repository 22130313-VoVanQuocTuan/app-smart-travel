package com.example.smart_travel_BE.dto.invoice.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActiveInvoiceResponse {

    private Long bookingId;
    private String invoiceNumber;
    private String itemName;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer nights;
    private String status;
    private String paymentMethod;
    private boolean isReviewed;
}
