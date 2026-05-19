package com.example.smart_travel_BE.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "vouchers")
@Data
public class Voucher {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String code;

    @Column(name = "discount_type", length = 20)
    private String discountType = "FIXED"; // FIXED hoặc PERCENTAGE

    @Column(name = "discount_amount", nullable = false)
    private BigDecimal discountAmount; // Số tiền giảm hoặc % giảm

    @Column(name = "max_discount")
    private BigDecimal maxDiscount; // Giảm tối đa (cho %)

    @Column(name = "min_order_value")
    private BigDecimal minOrderValue; // Đơn hàng tối thiểu

    @Column(name = "expiry_date")
    private LocalDateTime expiryDate;

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "usage_limit")
    private Integer usageLimit; // Giới hạn số lần dùng

    @Column(name = "used_count")
    private Integer usedCount = 0; // Số lần đã dùng

    @Column(name = "points_required")
    private Long pointsRequired;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (isActive == null) isActive = true;
        if (usedCount == null) usedCount = 0;
        if (discountType == null) discountType = "FIXED";
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}