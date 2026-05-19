package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.SystemConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SystemConfigRepository extends JpaRepository<SystemConfig, Integer> {
    @Query(value = "SELECT * FROM system_configs LIMIT 1", nativeQuery = true)
    Optional<SystemConfig> findFirstConfig();
}

