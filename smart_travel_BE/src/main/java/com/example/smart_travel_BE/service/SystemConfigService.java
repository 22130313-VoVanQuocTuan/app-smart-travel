package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.systemconfig.request.SystemConfigUpdateRequest;
import com.example.smart_travel_BE.dto.systemconfig.response.SystemConfigResponse;
import com.example.smart_travel_BE.entity.SystemConfig;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.mapper.SystemConfigMapper;
import com.example.smart_travel_BE.repository.SystemConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service quản lý cấu hình hệ thống
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemConfigService {

    private final SystemConfigRepository systemConfigRepository;
    private final SystemConfigMapper systemConfigMapper;
    private static final Integer DEFAULT_CONFIG_ID = 1; // Luôn sử dụng ID 1 cho cấu hình hệ thống


    /**
     * Lấy cấu hình hệ thống hiện tại
     */
    public SystemConfigResponse getSystemConfig() {
        SystemConfig config = systemConfigRepository.findById(DEFAULT_CONFIG_ID)
                .orElseThrow(() -> {
                    log.warn("Cấu hình hệ thống không tồn tại, tạo cấu hình mặc định");
                    return new AppException(ErrorCode.NOT_FOUND);
                });
        return systemConfigMapper.toSystemConfigResponse(config);
    }

    /**
     * Cập nhật cấu hình hệ thống (chỉ ADMIN)
     */
    @PreAuthorize("hasRole('ADMIN')")
    @Transactional
    public SystemConfigResponse updateSystemConfig(SystemConfigUpdateRequest request) {
        log.info("Cập nhật cấu hình hệ thống: {}", request);

        SystemConfig config = systemConfigRepository.findById(DEFAULT_CONFIG_ID)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        // Cập nhật các trường từ request
        systemConfigMapper.updateSystemConfigFromRequest(request, config);

        SystemConfig updated = systemConfigRepository.save(config);
        log.info("Cấu hình hệ thống đã được cập nhật");

        return systemConfigMapper.toSystemConfigResponse(updated);
    }


}

