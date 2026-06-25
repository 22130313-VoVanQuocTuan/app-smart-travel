package com.example.smart_travel_BE.util;

import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Utility class để lấy thông tin user hiện tại từ SecurityContext
 */
@Component
@Slf4j
public class SecurityUtil {

    /**
     * Lấy user hiện tại từ SecurityContext
     * @return User object nếu có, ngược lại throw AppException
     */
    public User getUserDetail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null || authentication.getPrincipal() == null) {
            log.warn("No authentication found in SecurityContext");
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        if (authentication.getPrincipal() instanceof User) {
            return (User) authentication.getPrincipal();
        }

        log.warn("Principal is not a User instance: {}", authentication.getPrincipal().getClass());
        throw new AppException(ErrorCode.UNAUTHENTICATED);
    }

    /**
     * Lấy email của user hiện tại
     * @return Email của user
     */
    public String getCurrentUserEmail() {
        User user = getUserDetail();
        return user.getEmail();
    }

    /**
     * Lấy ID của user hiện tại
     * @return ID của user
     */
    public Long getCurrentUserId() {
        User user = getUserDetail();
        return user.getId();
    }

    /**
     * Kiểm tra user hiện tại có được xác thực không
     * @return true nếu được xác thực, false nếu không
     */
    public boolean isAuthenticated() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.isAuthenticated() 
                && !(authentication.getPrincipal() instanceof String && authentication.getPrincipal().equals("anonymousUser"));
    }

    /**
     * Kiểm tra user hiện tại có role cụ thể không
     * @param role vai trò cần kiểm tra
     * @return true nếu user có role đó, false nếu không
     */
    public boolean hasRole(String role) {
        if (!isAuthenticated()) {
            return false;
        }
        User user = getUserDetail();
        return user.getRole() != null && user.getRole().equalsIgnoreCase(role);
    }

    /**
     * Lấy authentication object hiện tại
     * @return Authentication object
     */
    public Authentication getAuthentication() {
        return SecurityContextHolder.getContext().getAuthentication();
    }
}

