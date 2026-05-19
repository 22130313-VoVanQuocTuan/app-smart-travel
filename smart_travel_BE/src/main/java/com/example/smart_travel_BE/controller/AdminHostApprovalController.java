package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.user.request.HostApprovalRequest;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.dto.user.response.HostApprovalResponse;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.service.HostApprovalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/host-approval")
@RequiredArgsConstructor
@Slf4j
public class AdminHostApprovalController {

    private final HostApprovalService hostApprovalService;

    /**
     * Lấy danh sách HOST chờ duyệt
     * Chỉ ADMIN mới có quyền truy cập
     */
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<APIResponse<Page<HostApprovalResponse>>> getPendingHostApprovals(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<HostApprovalResponse> result = hostApprovalService.getPendingHostApprovals(pageable);
            return ResponseEntity.ok(
                    APIResponse.<Page<HostApprovalResponse>>builder()
                            .msg("Danh sách HOST chờ duyệt")
                            .data(result)
                            .build()
            );
        } catch (Exception e) {
            log.error("Error fetching pending host approvals", e);
            return ResponseEntity.badRequest().body(
                    APIResponse.<Page<HostApprovalResponse>>builder()
                            .msg("Lỗi: " + e.getMessage())
                            .build()
            );
        }
    }

    /**
     * Duyệt HOST
     * Chỉ ADMIN mới có quyền
     */
    @PostMapping("/approve")
    @PreAuthorize("hasAnyRole('ADMIN', 'ADMINHOMESTAY')")
    public ResponseEntity<APIResponse<Void>> approveHost(
            @RequestParam Long userId) {
        try {
            hostApprovalService.approveHost(userId);
            return ResponseEntity.ok(
                    APIResponse.<Void>builder()
                            .msg("Đã duyệt HOST thành công")
                            .build()
            );
        } catch (AppException e) {
            log.error("Error approving host", e);
            return ResponseEntity.badRequest().body(
                    APIResponse.<Void>builder()
                            .msg(e.getMessage())
                            .build()
            );
        } catch (Exception e) {
            log.error("Unexpected error approving host", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    APIResponse.<Void>builder()
                            .msg("Lỗi: " + e.getMessage())
                            .build()
            );
        }
    }

    /**
     * Từ chối HOST
     * Chỉ ADMIN mới có quyền
     */
    @PostMapping("/reject")
    @PreAuthorize("hasAnyRole('ADMIN', 'ADMINHOMESTAY')")
    public ResponseEntity<APIResponse<Void>> rejectHost(
            @RequestParam Long userId,
            @RequestParam(defaultValue = "Không đủ điều kiện") String reason) {
        try {
            hostApprovalService.rejectHost(userId, reason);
            return ResponseEntity.ok(
                    APIResponse.<Void>builder()
                            .msg("Đã từ chối HOST")
                            .build()
            );
        } catch (AppException e) {
            log.error("Error rejecting host", e);
            return ResponseEntity.badRequest().body(
                    APIResponse.<Void>builder()
                            .msg(e.getMessage())
                            .build()
            );
        } catch (Exception e) {
            log.error("Unexpected error rejecting host", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    APIResponse.<Void>builder()
                            .msg("Lỗi: " + e.getMessage())
                            .build()
            );
        }
    }
}

