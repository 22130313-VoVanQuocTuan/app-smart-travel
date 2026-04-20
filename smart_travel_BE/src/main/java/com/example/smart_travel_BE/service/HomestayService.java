package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.hotel.request.HomestayFilterRequest;
//import com.example.smart_travel_BE.dto.hotel.request.HotelCreateRequest;
//import com.example.smart_travel_BE.dto.hotel.request.RoomTypeCreateRequest;
//import com.example.smart_travel_BE.dto.hotel.response.HotelDetailResponse;
import com.example.smart_travel_BE.dto.hotel.response.HomestayResponse;
//import com.example.smart_travel_BE.dto.hotel.response.RoomTypeResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.repository.*;
import com.example.smart_travel_BE.specification.HomestaySpecification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
public class HomestayService {

    @Autowired
    private HomestayRepository hotelRepository;
    @Autowired
    private UserRepository userRepository;

    ObjectMapper mapper = new ObjectMapper();

    //Lấy danh sách khách sạn có phân trang + filter
    public Page<HomestayResponse> getHotels(HomestayFilterRequest filter) {
        int page = (filter.getPage() != null && filter.getPage() >= 0) ? filter.getPage() : 0;
        int size = (filter.getSize() != null && filter.getSize() > 0) ? filter.getSize() : 10;

        Sort.Direction direction = "desc".equalsIgnoreCase(filter.getSortDir()) ? Sort.Direction.DESC : Sort.Direction.ASC;

        Sort sort = Sort.by(direction, filter.getSortBy());
        Pageable pageable = PageRequest.of(page, size, sort);

        // 1. LẤY USER_ID TỪ SECURITY CONTEXT
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Long currentUserId = null;
        boolean isHotelAdmin = false;

        if (auth != null && auth.isAuthenticated()) {
            if (auth.getPrincipal() instanceof com.example.smart_travel_BE.entity.User user) {
                currentUserId = user.getId();
            }
            System.out.println("Authorities thực tế: " + auth.getAuthorities());
            isHotelAdmin = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINHOTEL"));
        }

        // 2. Khởi tạo Spec
        Specification<Hotel> spec = HomestaySpecification.filter(filter);

        // 3. ĐIỀU KIỆN CHUNG: isActive = true
        Specification<Hotel> activeSpec = (root, query, cb) -> cb.equal(root.get("isActive"), true);
        spec = (spec == null) ? activeSpec : spec.and(activeSpec);

        // 4. NẾU LÀ ADMIN_HOTEL: Ép lọc theo ownerId (Số Long)
        Specification<Hotel> ownerSpec = null;
        if (isHotelAdmin && currentUserId != null) {
            final Long finalUserId = currentUserId;

            ownerSpec = (root, query, cb) -> cb.equal(root.get("owner").get("id"), finalUserId);

            spec = spec.and(ownerSpec);
        }
        Page<Hotel> hotelPage = hotelRepository.findAll(spec, pageable);
        System.out.println("Final currentUserId: " + currentUserId);
        System.out.println("Is Hotel Admin: " + isHotelAdmin);

        // 5. Map sang DTO (Giữ nguyên logic của bạn)
        return hotelPage.map(hotel -> HomestayResponse.builder().id(hotel.getId()).name(hotel.getName()).address(hotel.getAddress()).minPrice(hotel.getMinPrice()).stars(hotel.getStarRating()).rating(hotel.getAverageRating() != null ? hotel.getAverageRating().doubleValue() : null).numOfReviews(hotel.getReviewCount()).thumbnail(hotel.getThumbnail()).destinationId(hotel.getDestination() != null ? hotel.getDestination().getId() : null).destinationName(hotel.getDestination() != null ? hotel.getDestination().getName() : null).phone(hotel.getPhone()).email(hotel.getEmail()).description(hotel.getDescription()).amenities(convertAmenitiesToList(hotel.getAmenities())).totalRooms(hotel.getTotalRooms()).availableRooms(hotel.getAvailableRooms()).latitude(hotel.getLatitude()).longitude(hotel.getLongitude()).build());
    }

    // Hàm hỗ trợ convert
    private List<String> convertAmenitiesToList(String jsonAmenities) {
        if (jsonAmenities == null || jsonAmenities.isBlank()) {
            return new ArrayList<>();
        }
        try {
            // Parse chuỗi "['a','b']" thành List ["a","b"]
            return mapper.readValue(jsonAmenities, new TypeReference<List<String>>() {
            });
        } catch (JsonProcessingException e) {
            // Nếu lỗi (hoặc dữ liệu cũ không phải JSON), trả về list chứa chuỗi gốc
            return Collections.singletonList(jsonAmenities);
        }
    }

    // Hàm bổ trợ lấy Email người dùng đang đăng nhập
    private String getCurrentUserEmail() {
        Authentication authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new RuntimeException("Người dùng chưa xác thực!");
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof User) {
            return ((User) principal).getEmail();
        }
        return authentication.getName();
    }

    private void validateOwnership(Hotel hotel) {
        String currentPrincipal = getCurrentUserEmail();
        boolean isOwner = hotel.getOwner().getEmail().equalsIgnoreCase(currentPrincipal) || hotel.getOwner().getId().toString().equals(currentPrincipal);

        if (!isOwner) {
            throw new RuntimeException("Bạn không có quyền thực hiện thao tác này trên khách sạn của owner khác!");
        }
    }
}