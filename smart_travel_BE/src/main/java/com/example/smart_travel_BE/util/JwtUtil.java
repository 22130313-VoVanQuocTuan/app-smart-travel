package com.example.smart_travel_BE.util;

import com.example.smart_travel_BE.entity.RefreshToken;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.RefreshTokenRepository;
import com.example.smart_travel_BE.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.experimental.NonFinal;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;


import java.security.Key;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;


@Component
@Slf4j
@RequiredArgsConstructor
public class JwtUtil {


    @NonFinal
    @Value("${jwt.signerKey}")
    private String signerKey;

    @NonFinal
    @Value("${jwt.valid-duration}")
    private Long accessTokenValidity;

    @NonFinal
    @Value("${jwt.refreshable-duration}")
    private Long refreshTokenValidity;

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;

    // Clock skew để xử lý sai lệch thời gian server (60 giây)
    private static final long CLOCK_SKEW_SECONDS = 60;

    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(signerKey.getBytes());
    }

    public String generateToken(Long userID, Map<String, Object> claims) {
        return createToken(claims, userID, accessTokenValidity);
    }

    public String generateRefreshToken(Long userID) {
        String refreshToken = createToken(new HashMap<>(), userID, refreshTokenValidity);
        LocalDateTime expiryDate = LocalDateTime.now().plusSeconds(refreshTokenValidity);
        // Tìm user theo USERID
        var user = userRepository.findById(userID)
                .orElseThrow(() -> new AppException(ErrorCode.ACCOUNT_NOT_FOUND));
        refreshTokenRepository.save(RefreshToken.builder()
                .expiryDate(expiryDate)
                .token(refreshToken)
                .user(user)
                .build());

        return refreshToken;
    }

    private String createToken(Map<String, Object> claims, long subject, long validity) {

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(String.valueOf(subject))
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + validity * 1000))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }


    public String extractSubjectAsUserId(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    public Claims extractAllClaims(String token) {
        try {
            return Jwts
                    .parser()
                    .setSigningKey(getSigningKey())
                    .build()
                    .parseClaimsJws(token.trim())
                    .getBody();
        } catch (io.jsonwebtoken.ExpiredJwtException ex) {
            log.warn("Token đã hết hạn: {}", ex.getMessage());
            throw ex;
        } catch (Exception ex) {
            log.error("Lỗi khi parse JWT: {}", ex.getMessage());
            throw ex;
        }
    }

    public Boolean isTokenExpired(String token) {
        try {
            Date expiration = extractExpiration(token);
            Date now = new Date();
            // Cho phép sai lệch CLOCK_SKEW_SECONDS giây
            long clockSkewMillis = CLOCK_SKEW_SECONDS * 1000;
            return expiration.before(new Date(now.getTime() - clockSkewMillis));
        } catch (io.jsonwebtoken.ExpiredJwtException ex) {
            return true; // Token đã hết hạn
        } catch (Exception ex) {
            log.error("Lỗi khi kiểm tra hết hạn token: {}", ex.getMessage());
            return true; // Nếu có lỗi, coi như token hết hạn
        }
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
}