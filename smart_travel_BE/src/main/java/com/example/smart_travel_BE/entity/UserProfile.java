package com.example.smart_travel_BE.entity;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

@Entity
@Table(name = "user_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Quan hệ 1-1 với bảng users
    @OneToOne(fetch = FetchType.LAZY)
    @JsonIgnore
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(columnDefinition = "TEXT")
    private String bio;

    @Column(length = 10)
    private String gender;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(length = 100)
    private String address;

    @Column(length = 50)
    private String city;

    @Column(length = 50)
    private String country;

    // Fields for host verification
    @Column(name = "id_card_number", length = 100)
    private String idCardNumber;

    @Column(name = "id_card_image_url", length = 500)
    private String idCardImageUrl;

    @Column(name = "ownership_document_url", length = 500)
    private String ownershipDocumentUrl;

    @Column(name = "portrait_url", length = 500)
    private String portraitUrl;

    @Column(name = "host_verified")
    private Boolean hostVerified = false;

    @Column(columnDefinition = "TEXT")
    private String notificationSettings;

    @Column(columnDefinition = "TEXT")
    private String languageSettings;

    @Builder.Default
    private Boolean darkModeEnabled = false;

    @Builder.Default
    @Column(name = "experience_points")
    private Long experiencePoints = 0L;

    @Builder.Default
    @Column(name = "current_level", length = 50)
    private String currentLevel = "Đồng";

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;


    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}