package com.example.smart_travel_BE.dto.booking.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CancellationPolicyResponse {
    private boolean canCancel;
    private Integer cancelBeforeHours;          // Số giờ phải hủy trước
    private String cancelDeadline;              // Thời hạn hủy (dạng text)
    private BigDecimal cancellationFeePercent;  // Phí hủy (%)
    private BigDecimal estimatedCancellationFee; // Phí hủy ước tính (nếu hủy bây giờ)
    private String message;                      // Thông báo cho khách
}