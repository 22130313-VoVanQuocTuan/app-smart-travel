package com.example.smart_travel_BE.dto.systemconfig.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemConfigUpdateRequest {

    @JsonProperty("reminder_before_minutes")
    @Min(value = 1, message = "Nhắc nhở phải lớn hơn 0 phút")
    private Integer reminderBeforeMinutes;

    @JsonProperty("cancel_before_hours")
    @Min(value = 1, message = "Hủy phải lớn hơn 0 giờ")
    private Integer cancelBeforeHours;

    @JsonProperty("commission_rate")
    @DecimalMin(value = "0.0", message = "Tỷ lệ hoa hồng không được âm")
    @DecimalMax(value = "100.0", message = "Tỷ lệ hoa hồng không được vượt quá 100%")
    private BigDecimal commissionRate;

    @JsonProperty("cancellation_fee_percent")
    @DecimalMin(value = "0.0", message = "Phí hủy không được âm")
    @DecimalMax(value = "100.0", message = "Phí hủy không được vượt quá 100%")
    private BigDecimal cancellationFeePercent;

    @JsonProperty("tax_rate")
    @DecimalMin(value = "0.0", message = "Thuế suất không được âm")
    @DecimalMax(value = "100.0", message = "Thuế suất không được vượt quá 100%")
    private BigDecimal taxRate;
}

