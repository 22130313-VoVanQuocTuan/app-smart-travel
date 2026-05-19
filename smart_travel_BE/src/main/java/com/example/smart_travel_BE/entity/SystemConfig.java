package com.example.smart_travel_BE.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "system_configs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SystemConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // Thời gian
    @Column(name = "reminder_before_minutes")
    private Integer reminderBeforeMinutes;  // Nhắc trước bao nhiêu phút

    @Column(name = "cancel_before_hours")
    private Integer cancelBeforeHours;  // Hủy trước bao nhiêu giờ để không bị phạt

    // Hoa hồng
    @Column(name = "commission_rate", precision = 5, scale = 2)
    private BigDecimal commissionRate = BigDecimal.ZERO;  // Tỷ lệ hoa hồng (%)

    @Column(name = "tax_rate", precision = 5, scale = 2)
    private BigDecimal taxRate = BigDecimal.ZERO;  // Thuế suất (%)

    // Phí hủy phòng
    @Column(name = "cancellation_fee_percent", precision = 5, scale = 2)
    private BigDecimal cancellationFeePercent = BigDecimal.ZERO;  // Phí hủy (% giá trị booking)

    // Audit
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}