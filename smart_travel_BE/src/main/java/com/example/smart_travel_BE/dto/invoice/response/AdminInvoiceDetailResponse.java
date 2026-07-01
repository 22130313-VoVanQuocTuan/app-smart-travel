package com.example.smart_travel_BE.dto.invoice.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class AdminInvoiceDetailResponse {
    private Long bookingId;
    private String invoiceNumber;

    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private Long hotelId;
    private Long tourId;

    private String serviceName;
    private String roomTypeName;

    private LocalDate startDate;
    private LocalDate endDate;
    private Integer numberOfPeople;
    private Integer numberOfRooms;
    private String specialRequests;
    private String cancellationReason;

    private BigDecimal totalPrice;
    private BigDecimal discountAmount;
    private BigDecimal finalPrice;
    private BigDecimal taxRate;
    private BigDecimal totalWithTax;

    private String paymentStatus;
    private String paymentMethod;

    private BigDecimal taxAmount;

    private String refundBankName;
    private String refundBankBranch;
    private String refundAccountNumber;
    private String refundAccountHolder;
    private LocalDateTime refundRequestedAt;
    private LocalDateTime refundApprovedAt;

    private String customerName;
    private String customerPhone;
    private String customerEmail;
}
