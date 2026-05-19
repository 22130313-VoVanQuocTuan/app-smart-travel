package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.user.request.HostApprovalRequest;
import com.example.smart_travel_BE.dto.user.response.HostApprovalResponse;
import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.entity.UserProfile;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.UserProfileRepository;
import com.example.smart_travel_BE.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class HostApprovalService {
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    /**
     * Lấy danh sách HOST chưa được duyệt (chỉ ADMIN)
     */
    public Page<HostApprovalResponse> getPendingHostApprovals(Pageable pageable) {
        // Lấy all users với role = HOST và hostVerified = false
        return userRepository.findPendingHosts("HOST", true, pageable)
                .map(this::convertToHostApprovalResponse);
    }

    /**
     * Lấy danh sách tất cả HOST đã được duyệt (optional cho admin xem)
     */
    public Page<HostApprovalResponse> getApprovedHosts(Pageable pageable) {
        return userRepository.findApprovedHosts("HOST", true, pageable)
                .map(this::convertToHostApprovalResponse);
    }

    /**
     * Duyệt HOST (cập nhật hostVerified=true)
     */
    @Transactional
    public void approveHost(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.ACCOUNT_NOT_FOUND));

        if (!"HOST".equalsIgnoreCase(user.getRole())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        UserProfile profile = userProfileRepository.findByUser(user)
                .orElseThrow(() -> new AppException(ErrorCode.ACCOUNT_NOT_FOUND));

        profile.setHostVerified(true);
        userProfileRepository.save(profile);

        log.info("Host approved: userId={}, email={}", userId, user.getEmail());
    }

    /**
     * Từ chối HOST (có thể set lại role thành USER hoặc giữ lại để reapply)
     */
    @Transactional
    public void rejectHost(Long userId, String reason) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.ACCOUNT_NOT_FOUND));

        if (!"HOST".equalsIgnoreCase(user.getRole())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        UserProfile profile = userProfileRepository.findByUser(user)
                .orElseThrow(() -> new AppException(ErrorCode.ACCOUNT_NOT_FOUND));

        // Giữ hostVerified = false và role = HOST (để họ có thể reapply sau)
        // Nếu bạn muốn chuyển lại thành USER, hãy uncomment dòng dưới
        // user.setRole("USER");
        // userRepository.save(user);

        log.info("Host rejected: userId={}, email={}, reason={}", userId, user.getEmail(), reason);
    }

    /**
     * Convert User + UserProfile → HostApprovalResponse
     */
    private HostApprovalResponse convertToHostApprovalResponse(User user) {
        UserProfile profile = userProfileRepository.findByUser(user).orElse(null);
        return HostApprovalResponse.builder()
                .userId(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .idCardNumber(profile != null ? profile.getIdCardNumber() : null)
                .idCardImageUrl(profile != null ? profile.getIdCardImageUrl() : null)
                .ownershipDocumentUrl(profile != null ? profile.getOwnershipDocumentUrl() : null)
                .portraitUrl(profile != null ? profile.getPortraitUrl() : null)
                .hostVerified(profile != null ? profile.getHostVerified() : false)
                .createdAt(user.getCreatedAt())
                .build();
    }
}

