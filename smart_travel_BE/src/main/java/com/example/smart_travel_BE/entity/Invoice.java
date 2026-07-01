package com.example.smart_travel_BE.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "invoice",
        indexes = {
                @Index(name = "idx_booking_id", columnList = "booking_id"),
                @Index(name = "idx_invoice_number", columnList = "invoice_number")
        })
public class Invoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false)
    private Booking booking;

    @Column(name = "invoice_number", nullable = false, unique = true, length = 50)
    private String invoiceNumber;

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "tax_amount", precision = 12, scale = 2)
    private BigDecimal taxAmount = BigDecimal.ZERO;

    @Column(name = "item_details", nullable = false, columnDefinition = "JSON")
    private String itemDetails;

    @Column(name = "issue_date", nullable = false)
    private LocalDate issueDate;

    @Column(name = "is_reviewed", nullable = false)
    private boolean isReviewed = false;

    @Column(name = "commission_percentage", precision = 5, scale = 2)
    private BigDecimal commissionPercentage; // Tỷ lệ hoa hồng (vd: 10.00 = 10%)

    @Column(name = "commission_amount", precision = 12, scale = 2)
    private BigDecimal commissionAmount; // Số tiền hoa hồng

    @Column(name = "homestay_amount", precision = 12, scale = 2)
    private BigDecimal homestayAmount; // Số tiền Homestay nhận được (total - commission)

    @Column(name = "commission_status")
    @Enumerated(EnumType.STRING)
    private CommissionStatus commissionStatus; // Trạng thái thanh toán hoa hồng

    @Column(name = "commission_paid_at")
    private LocalDateTime commissionPaidAt; // Thời gian thanh toán hoa hồng

    @Column(name = "refund_bank_name", length = 150)
    private String refundBankName;

    @Column(name = "refund_bank_branch", length = 150)
    private String refundBankBranch;

    @Column(name = "refund_account_number", length = 50)
    private String refundAccountNumber;

    @Column(name = "refund_account_holder", length = 150)
    private String refundAccountHolder;

    @Column(name = "refund_requested_at")
    private LocalDateTime refundRequestedAt;

    @Column(name = "refund_approved_at")
    private LocalDateTime refundApprovedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
