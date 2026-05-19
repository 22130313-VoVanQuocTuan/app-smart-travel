package com.example.smart_travel_BE.mapper;

import com.example.smart_travel_BE.dto.systemconfig.request.SystemConfigUpdateRequest;
import com.example.smart_travel_BE.dto.systemconfig.response.SystemConfigResponse;
import com.example.smart_travel_BE.entity.SystemConfig;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface SystemConfigMapper {

    SystemConfigResponse toSystemConfigResponse(SystemConfig systemConfig);

    SystemConfig toSystemConfig(SystemConfigUpdateRequest request);

    void updateSystemConfigFromRequest(SystemConfigUpdateRequest request, @MappingTarget SystemConfig systemConfig);
}

