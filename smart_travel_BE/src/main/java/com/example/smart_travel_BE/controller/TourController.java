package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.tour.request.TourCreateRequest;
import com.example.smart_travel_BE.dto.tour.response.TourResponse;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.service.TourService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/host/tours")
@RequiredArgsConstructor
public class TourController {

    private final TourService tourService;

    /**
     * Lấy danh sách tour của homestay
     * GET /api/v1/host/tours/homestay/{homestayId}
     */
    @GetMapping("/homestay/{homestayId}")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<List<TourResponse>>> getToursByHomestay(
            @PathVariable Long homestayId) {
        List<TourResponse> tours = tourService.getToursByHomestay(homestayId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<List<TourResponse>>builder()
                        .msg("Lấy danh sách tour thành công")
                        .data(tours)
                        .build());
    }

    /**
     * Lấy chi tiết tour
     * GET /api/v1/host/tours/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<APIResponse<TourResponse>> getTourDetail(@PathVariable Long id) {
        TourResponse response = tourService.getTourDetail(id);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<TourResponse>builder()
                        .msg("Lấy chi tiết tour thành công")
                        .data(response)
                        .build());
    }

    /**
     * Tạo tour mới cho homestay
     * POST /api/v1/host/tours
     */
    @PostMapping
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<TourResponse>> createTour(
            @ModelAttribute TourCreateRequest request) throws Exception {
        TourResponse response = tourService.createTour(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(APIResponse.<TourResponse>builder()
                        .msg("Tạo tour thành công")
                        .data(response)
                        .build());
    }

    /**
     * Cập nhật tour
     * PUT /api/v1/host/tours/{id}
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<TourResponse>> updateTour(
            @PathVariable Long id,
            @ModelAttribute TourCreateRequest request) throws Exception {
        TourResponse response = tourService.updateTour(id, request);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<TourResponse>builder()
                        .msg("Cập nhật tour thành công")
                        .data(response)
                        .build());
    }

    /**
     * Xóa tour
     * DELETE /api/v1/host/tours/{id}
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<Void>> deleteTour(@PathVariable Long id) {
        tourService.deleteTour(id);
        return ResponseEntity.status(HttpStatus.OK)
                .body(APIResponse.<Void>builder()
                        .msg("Xóa tour thành công")
                        .build());
    }
}