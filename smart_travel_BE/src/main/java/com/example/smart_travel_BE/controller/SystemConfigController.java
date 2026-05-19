package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.systemconfig.request.SystemConfigUpdateRequest;
import com.example.smart_travel_BE.dto.systemconfig.response.SystemConfigResponse;
import com.example.smart_travel_BE.service.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Controller quản lý cấu hình hệ thống
 */
@RestController
@RequestMapping("/api/v1/system-config")
@RequiredArgsConstructor
@Slf4j
public class SystemConfigController {

    private final SystemConfigService systemConfigService;

    /**
     * Lấy cấu hình hệ thống hiện tại
     * GET /api/v1/system-config
     */
    @GetMapping
    public ResponseEntity<SystemConfigResponse> getSystemConfig() {
        log.info("Lấy cấu hình hệ thống");
        SystemConfigResponse config = systemConfigService.getSystemConfig();
        return ResponseEntity.ok(config);
    }

    /**
     * Cập nhật cấu hình hệ thống (chỉ ADMIN)
     * PUT /api/v1/system-config
     */
    @PutMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SystemConfigResponse> updateSystemConfig(@RequestBody SystemConfigUpdateRequest request) {
        log.info("Cập nhật cấu hình hệ thống");
        SystemConfigResponse updatedConfig = systemConfigService.updateSystemConfig(request);
        return ResponseEntity.ok(updatedConfig);
    }
}

