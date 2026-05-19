package com.example.smart_travel_BE.dto.user.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class HostApprovalRequest {
    @NotNull(message = "userId là bắt buộc")
    private Long userId;

    @NotNull(message = "approved là bắt buộc (true = duyệt, false = từ chối)")
    private Boolean approved;

    private String rejectReason; // Lý do từ chối (nếu approved = false)
}

