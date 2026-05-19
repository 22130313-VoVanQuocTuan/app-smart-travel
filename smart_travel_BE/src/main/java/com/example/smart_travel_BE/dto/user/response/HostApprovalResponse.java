package com.example.smart_travel_BE.dto.user.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HostApprovalResponse {
    private Long userId;
    private String fullName;
    private String email;
    private String phone;
    private String idCardNumber;
    private String idCardImageUrl;
    private String ownershipDocumentUrl;
    private String portraitUrl;
    private Boolean hostVerified;
    private LocalDateTime createdAt;
}

