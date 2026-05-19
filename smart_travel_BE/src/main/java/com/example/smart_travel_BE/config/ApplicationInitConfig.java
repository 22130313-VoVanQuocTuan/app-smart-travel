package com.example.smart_travel_BE.config;

import com.example.smart_travel_BE.entity.SystemConfig;
import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.repository.SystemConfigRepository;
import com.example.smart_travel_BE.repository.UserRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Configuration
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class ApplicationInitConfig {

    PasswordEncoder passwordEncoder;

    static final String ADMIN_EMAIL = "tuansdev@gmail.com";
    static final String ADMIN_PASSWORD = "tuansdev";

    static final String TEST_USER_EMAIL = "testuser@gmail.com";
    static final String TEST_USER_PASSWORD = "password123";

    @Bean
    @ConditionalOnProperty(
            prefix = "spring",
            value = "datasource.driver-class-name",
            havingValue = "com.mysql.cj.jdbc.Driver")
    ApplicationRunner applicationRunner(UserRepository userRepository, SystemConfigRepository systemConfigRepository) {
        log.info("Init Application Runner...");
        return args -> {

            // 1. Tạo Admin user nếu chưa có
            if (userRepository.findByEmail(ADMIN_EMAIL).isEmpty()) {
                User adminUser = User.builder()
                        .email(ADMIN_EMAIL)
                        .emailVerified(true)
                        .password(passwordEncoder.encode(ADMIN_PASSWORD))
                        .role("ADMIN")
                        .isActive(true)
                        .build();
                userRepository.save(adminUser);
                log.info("Admin user created: {}", ADMIN_EMAIL);
            }

            // 2. Tạo Test user nếu chưa có
            if (userRepository.findByEmail(TEST_USER_EMAIL).isEmpty()) {
                User testUser = User.builder()
                        .email(TEST_USER_EMAIL)
                        .emailVerified(true)
                        .password(passwordEncoder.encode(TEST_USER_PASSWORD))
                        .role("USER")
                        .fullName("User Test")
                        .isActive(true)
                        .build();
                userRepository.save(testUser);
                log.info("Test user created: {}", TEST_USER_EMAIL);
            }

            // 3. Khởi tạo cấu hình hệ thống (nếu chưa có)
            if (systemConfigRepository.count() == 0) {
                log.info("Khởi tạo cấu hình hệ thống mặc định");

                SystemConfig defaultConfig = SystemConfig.builder()
                        .reminderBeforeMinutes(60)           // Nhắc 60 phút trước
                        .cancelBeforeHours(24)               // Hủy được trước 24 giờ
                        .commissionRate(BigDecimal.valueOf(10))   // Hoa hồng 10%
                        .taxRate(BigDecimal.valueOf(10))          // Thuế VAT 10%
                        .taxRate(BigDecimal.valueOf(8))
                        .cancellationFeePercent(BigDecimal.valueOf(20))   // Phí hủy 20%
                        .updatedAt(LocalDateTime.now())
                        .build();

                systemConfigRepository.save(defaultConfig);
                log.info("System config created successfully");
            } else {
                log.info("System config already exists, skipping initialization");
            }

            log.info("Application initialization completed!");
        };
    }
}