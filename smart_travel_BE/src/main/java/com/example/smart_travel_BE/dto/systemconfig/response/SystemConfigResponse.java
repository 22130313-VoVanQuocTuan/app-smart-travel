package com.example.smart_travel_BE.dto.systemconfig.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemConfigResponse {

    @JsonProperty("id")
    private Integer id;

    @JsonProperty("reminder_before_minutes")
    private Integer reminderBeforeMinutes;

    @JsonProperty("cancel_before_hours")
    private Integer cancelBeforeHours;

    @JsonProperty("commission_rate")
    private BigDecimal commissionRate;

    @JsonProperty("cancellation_fee_percent")
    private BigDecimal cancellationFeePercent;

    @JsonProperty("tax_rate")
    private BigDecimal taxRate;

    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;
}

