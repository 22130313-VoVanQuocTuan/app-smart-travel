package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
    Optional<User> findByEmail(String email);

    Optional<User> findByPhone(String phone);

    boolean existsByEmail(String email);

    boolean existsByPhone(String phone);

    // Find users by role with pagination
    @Query("SELECT u FROM User u " +
            "JOIN UserProfile up ON up.user.id = u.id " +
            "WHERE u.role = :role " +
            "AND u.emailVerified = :emailVerified " +
            "AND up.hostVerified = false " +      // CHƯA được duyệt
            "ORDER BY u.createdAt DESC")
    Page<User> findPendingHosts(String role, Boolean emailVerified, Pageable pageable);

    @Query("SELECT u FROM User u " +
            "JOIN UserProfile up ON up.user.id = u.id " +
            "WHERE u.role = :role " +
            "AND u.emailVerified = :emailVerified " +
            "AND up.hostVerified = true " +       // ĐÃ được duyệt
            "ORDER BY u.createdAt DESC")
    Page<User> findApprovedHosts(String role, Boolean emailVerified, Pageable pageable);
    // Tìm tất cả user theo role
    List<User> findByRole(String role);

    // Đếm số lượng user theo role (for statistics)
    long countByRole(String role);
}
