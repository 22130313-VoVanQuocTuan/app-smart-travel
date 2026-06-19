package com.example.smart_travel_BE.controller;


import com.cloudinary.api.ApiResponse;
import com.example.smart_travel_BE.dto.homestay.request.HomestayCreateRequest;
import com.example.smart_travel_BE.dto.homestay.request.HomestayFilterRequest;
import com.example.smart_travel_BE.dto.homestay.response.HomestayDetailResponse;
import com.example.smart_travel_BE.dto.homestay.response.HomestayResponse;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.service.HomestayService;
import com.fasterxml.jackson.core.JsonProcessingException;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/homestays")
public class HomestayController {

    @Autowired
    private HomestayService homestayService;

    /**
     * 1. Lấy danh sách homestay (có phân trang + filter)
     * GET /api/v1/homestays?destinationId=1&minStars=3&page=0&size=10
     */
    @GetMapping
    public ResponseEntity<Page<HomestayResponse>> getHomestays(
            @RequestParam(required = false) Long destinationId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer minStars,
            @RequestParam(required = false) Integer maxStars,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String city,
            @RequestParam(required = false, defaultValue = "0") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size,
            @RequestParam(required = false, defaultValue = "pricePerNight") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String sortDir
    ) {
        log.info(sortDir);
        log.info(sortBy);
        HomestayFilterRequest req = new HomestayFilterRequest();
        req.setDestinationId(destinationId);
        req.setKeyword(keyword);
        req.setMinStars(minStars);
        req.setMaxStars(maxStars);
        if (minPrice != null) req.setMinPrice(BigDecimal.valueOf(minPrice));
        if (maxPrice != null) req.setMaxPrice(BigDecimal.valueOf(maxPrice));
        req.setCity(city);
        req.setPage(page);
        req.setSize(size);
        req.setSortBy(sortBy);
        req.setSortDir(sortDir);

        Page<HomestayResponse> response = homestayService.getHomestay(req);
        return ResponseEntity.ok(response);
    }

    /**
     * 2. Lấy thông tin chi tiết homestay + phòng trống + tour kèm theo ngày
     * GET /api/v1/homestays/5/detail?checkIn=2025-10-15&checkOut=2025-10-20
     */
    @GetMapping("/{id}/detail")
    public ResponseEntity<HomestayDetailResponse> getHomestayDetail(
            @PathVariable("id") Long homestayId,
            @RequestParam(value = "checkIn", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam(value = "checkOut", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(value = "forEdit", required = false, defaultValue = "false") boolean forEdit
    ) {
        LocalDate in = (checkIn != null) ? checkIn : LocalDate.now();
        LocalDate out = (checkOut != null) ? checkOut : in.plusDays(1);

        if (out.isBefore(in) || out.equals(in)) {
            out = in.plusDays(1);
        }

        HomestayDetailResponse response = homestayService.getHomestayDetail(homestayId, in, out, forEdit);
        return ResponseEntity.ok(response);
    }

    /**
     * 3. Tạo mới homestay (Chỉ ADMIN_HOTEL)
     * POST /api/v1/homestays
     */
    @PostMapping
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<HomestayDetailResponse>> createHomestay(
            @Valid @ModelAttribute HomestayCreateRequest request
    ) throws JsonProcessingException, IOException {
        HomestayDetailResponse response = homestayService.createHomestay(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(APIResponse.<HomestayDetailResponse>builder()
                        .msg("Tạo homestay thành công")
                        .data(response)
                        .build());
    }

    @PutMapping(value = "/{id}")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<HomestayDetailResponse>> updateHomestay(
            @PathVariable("id") Long homestayId,
            @Valid @ModelAttribute HomestayCreateRequest request
    ) throws JsonProcessingException, IOException {
        HomestayDetailResponse response = homestayService.updateHomestay(homestayId, request);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<HomestayDetailResponse>builder()
                        .msg("Cập nhật homestay thành công")
                        .data(response)
                        .build());
    }

    /**
     * 5. Xóa homestay (soft delete - Chỉ chủ sở hữu)
     * DELETE /api/v1/homestays/{id}
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<Void>> deleteHomestay(
            @PathVariable("id") Long homestayId
    ) {
        homestayService.deleteHomestay(homestayId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<Void>builder()
                        .msg("Xóa homestay thành công")
                        .build());
    }

    /**
     * 6. Lấy danh sách homestay theo chủ sở hữu (Chính chủ)
     * GET /api/v1/homestays/owner/my-homestays
     */
    @GetMapping("/owner/my-homestays")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<List<HomestayResponse>>> getHomestaysByOwner() {
        List<HomestayResponse> responses = homestayService.getHomestaysByCurrentOwner();
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<HomestayResponse>>builder()
                        .msg("Lấy danh sách homestay của bạn thành công")
                        .data(responses)
                        .build());
    }

    /**
     * 7. Lấy danh sách homestay nổi bật (top rating)
     * GET /api/v1/homestays/featured?limit=5
     */
    @GetMapping("/featured")
    public ResponseEntity<APIResponse<List<HomestayResponse>>> getFeaturedHomestays(
            @RequestParam(defaultValue = "5") Integer limit
    ) {
        List<HomestayResponse> responses = homestayService.getFeaturedHomestays(limit);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<HomestayResponse>>builder()
                        .msg("Lấy danh sách homestay nổi bật thành công")
                        .data(responses)
                        .build());    }

    /**
     * 7b. Lấy danh sách homestay có doanh thu cao nhất (top revenue)
     * GET /api/v1/homestays/top-revenue?limit=5
     */
    @GetMapping("/top-revenue")
    public ResponseEntity<APIResponse<List<HomestayResponse>>> getTopRevenueHomestays(
            @RequestParam(defaultValue = "5") Integer limit
    ) {
        List<HomestayResponse> responses = homestayService.getTopHomestaysByRevenue(limit);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<HomestayResponse>>builder()
                        .msg("Lấy danh sách homestay doanh thu cao thành công")
                        .data(responses)
                        .build());
    }

    /**
     * 8. Lấy danh sách homestay theo destination
     * GET /api/v1/homestays/destination/{destinationId}
     */
    @GetMapping("/destination/{destinationId}")
    public ResponseEntity<APIResponse<List<HomestayResponse>>> getHomestaysByDestination(
            @PathVariable Long destinationId
    ) {
        List<HomestayResponse> responses = homestayService.getHomestaysByDestination(destinationId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<HomestayResponse>>builder()
                        .msg("Lấy danh sách theo địa điểm thành công")
                        .data(responses)
                        .build());    }

    /**
     * 9. Tìm kiếm homestay theo khoảng giá
     * GET /api/v1/homestays/search/price-range?minPrice=500000&maxPrice=2000000
     */
    @GetMapping("/search/price-range")
    public ResponseEntity<APIResponse<List<HomestayResponse>>> getHomestaysByPriceRange(
            @RequestParam Double minPrice,
            @RequestParam Double maxPrice
    ) {
        List<HomestayResponse> responses = homestayService.getHomestaysByPriceRange(
                BigDecimal.valueOf(minPrice),
                BigDecimal.valueOf(maxPrice)
        );
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<HomestayResponse>>builder()
                        .msg("Tìm kiếm homestay thành công")
                        .data(responses)
                        .build());
    }

    /**
     * 10. Lấy danh sách phòng trống của homestay theo ngày
     * GET /api/v1/homestays/{id}/available-rooms?checkIn=2025-10-15&checkOut=2025-10-20
     */
    @GetMapping("/{id}/available-rooms")
    public ResponseEntity<APIResponse<Map<String, Object>>> getAvailableRooms(
            @PathVariable("id") Long homestayId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut
    ) {
        Map<String, Object> response = homestayService.getAvailableRooms(homestayId, checkIn, checkOut);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<Map<String, Object>>builder()
                        .msg("Lấy danh sách phòng trống thành công")
                        .data(response)
                        .build());    }

    /**
     * 11. Lấy danh sách tour có thể đặt kèm homestay
     * GET /api/v1/homestays/{id}/available-tours?checkIn=2025-10-15&checkOut=2025-10-20
     */
    @GetMapping("/{id}/available-tours")
    public ResponseEntity<APIResponse<List<?>>> getAvailableTours(
            @PathVariable("id") Long homestayId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut
    ) {
        List<?> response = homestayService.getAvailableToursForHomestay(homestayId, checkIn, checkOut);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<?>>builder()
                        .msg("Lấy danh sách tour có thể ặt kèm homestay thành công")
                        .data(response)
                        .build());
    }

    /**
     * 12. Kiểm tra phòng trống
     * GET /api/v1/homestays/{id}/check-availability?checkIn=2025-10-15&checkOut=2025-10-20&numberOfRooms=2
     */
    @GetMapping("/{id}/check-availability")
    public ResponseEntity<APIResponse<Boolean>> checkAvailability(
            @PathVariable("id") Long homestayId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam Integer numberOfRooms,
            @RequestParam Long roomTypeId
    ) {
        boolean isAvailable = homestayService.checkAvailability(homestayId, roomTypeId, checkIn, checkOut, numberOfRooms);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<Boolean>builder()
                        .msg("Kiểm tra phòng trống thành công")
                        .data(isAvailable)
                        .build());
    }
}