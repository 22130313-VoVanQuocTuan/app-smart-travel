package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.booking.request.BookingRequest;
import com.example.smart_travel_BE.dto.booking.request.CancelBookingRequest;
import com.example.smart_travel_BE.dto.booking.response.BookingResponse;
import com.example.smart_travel_BE.dto.booking.response.CancellationPolicyResponse;
import com.example.smart_travel_BE.dto.booking.response.HostBookingListResponse;
import com.example.smart_travel_BE.dto.booking.response.UserBookingResponse;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.service.BookingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @PostMapping
    public ResponseEntity<BookingResponse> createBooking(
            @Valid @RequestBody BookingRequest bookingRequest,
            @AuthenticationPrincipal User currentUser
    ) {
        BookingResponse bookingResponse = bookingService.createBooking(bookingRequest, currentUser);
        return ResponseEntity.ok(bookingResponse);
    }

    /**
     * GET /api/v1/bookings/host/list
     * Lấy danh sách booking của host
     */
    @GetMapping("/host/list")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<List<HostBookingListResponse>>> getHostBookings(
            @AuthenticationPrincipal User currentUser
    ) {
        List<HostBookingListResponse> bookings = bookingService.getHostBookings(currentUser.getId());
        return ResponseEntity.ok(
            APIResponse.<List<HostBookingListResponse>>builder()
                .msg("Lấy danh sách booking thành công")
                .data(bookings)
                .build()
        );
    }

    /**
     * GET /api/v1/bookings/{id}/detail
     * Lấy chi tiết booking
     */
    @GetMapping("/{id}/detail")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<BookingResponse>> getHostBookingDetail(
            @PathVariable("id") Long bookingId,
            @AuthenticationPrincipal User currentUser
    ) {
        BookingResponse booking = bookingService.getHostBookingDetail(bookingId, currentUser.getId());
        return ResponseEntity.ok(
            APIResponse.<BookingResponse>builder()
                .msg("Lấy chi tiết booking thành công")
                .data(booking)
                .build()
        );
    }

    /**
     * GET /api/v1/bookings/host/calendar?startDate=2025-01-01&endDate=2025-01-31&status=PENDING
     * Lấy booking theo date range cho calendar view
     */
    @GetMapping("/host/calendar")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<List<HostBookingListResponse>>> getHostBookingsByDateRange(
            @AuthenticationPrincipal User currentUser,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String status
    ) {
        List<HostBookingListResponse> bookings = bookingService.getHostBookingsByDateRange(
            currentUser.getId(), startDate, endDate, status
        );
        return ResponseEntity.ok(
            APIResponse.<List<HostBookingListResponse>>builder()
                .msg("Lấy danh sách booking theo calendar thành công")
                .data(bookings)
                .build()
        );
    }

    /**
     * PUT /api/v1/bookings/{id}/status
     * Cập nhật trạng thái booking
     */
    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('HOST')")
    public ResponseEntity<APIResponse<Map<String, String>>> updateBookingStatus(
            @PathVariable("id") Long bookingId,
            @AuthenticationPrincipal User currentUser,
            @RequestBody Map<String, String> request
    ) {
        String newStatus = request.get("status");
        String cancellationReason = request.get("cancellationReason");
        
        bookingService.updateBookingStatus(bookingId, newStatus, currentUser.getId(), cancellationReason);
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Cập nhật trạng thái booking thành công");
        response.put("bookingId", bookingId.toString());
        response.put("newStatus", newStatus);
        
        return ResponseEntity.ok(
            APIResponse.<Map<String, String>>builder()
                .msg("Cập nhật trạng thái thành công")
                .data(response)
                .build()
        );
    }

    // ==================== USER BOOKING APIs ====================

    /**
     * GET /api/v1/bookings/user/list
     * Lấy tất cả booking của user hiện tại
     */
    @GetMapping("/user/list")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<List<UserBookingResponse>>> getUserBookings(
            @AuthenticationPrincipal User currentUser
    ) {
        List<UserBookingResponse> bookings = bookingService.getUserBookings(currentUser);
        return ResponseEntity.ok(
                APIResponse.<List<UserBookingResponse>>builder()
                        .msg("Lấy danh sách booking thành công")
                        .data(bookings)
                        .build()
        );
    }

    /**
     * GET /api/v1/bookings/user/current
     * Lấy booking hiện tại (đang diễn ra hoặc sắp diễn ra)
     */
    @GetMapping("/user/current")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<List<UserBookingResponse>>> getCurrentBookings(
            @AuthenticationPrincipal User currentUser
    ) {
        List<UserBookingResponse> bookings = bookingService.getCurrentBookings(currentUser);
        return ResponseEntity.ok(
                APIResponse.<List<UserBookingResponse>>builder()
                        .msg("Lấy danh sách booking hiện tại thành công")
                        .data(bookings)
                        .build()
        );
    }

    /**
     * GET /api/v1/bookings/user/history
     * Lấy lịch sử booking (đã hoàn thành hoặc đã hủy)
     */
    @GetMapping("/user/history")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<List<UserBookingResponse>>> getBookingHistory(
            @AuthenticationPrincipal User currentUser
    ) {
        List<UserBookingResponse> bookings = bookingService.getBookingHistory(currentUser);
        return ResponseEntity.ok(
                APIResponse.<List<UserBookingResponse>>builder()
                        .msg("Lấy lịch sử booking thành công")
                        .data(bookings)
                        .build()
        );
    }

    /**
     * GET /api/v1/bookings/user/detail/{bookingId}
     * Lấy chi tiết booking của user
     */
    @GetMapping("/user/detail/{bookingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<UserBookingResponse>> getUserBookingDetail(
            @PathVariable Long bookingId,
            @AuthenticationPrincipal User currentUser
    ) {
        UserBookingResponse booking = bookingService.getUserBookingDetail(bookingId, currentUser);
        return ResponseEntity.ok(
                APIResponse.<UserBookingResponse>builder()
                        .msg("Lấy chi tiết booking thành công")
                        .data(booking)
                        .build()
        );
    }

    /**
     * PUT /api/v1/bookings/user/cancel/{bookingId}
     * Hủy booking bởi user
     */
    @PutMapping("/user/cancel/{bookingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<Map<String, String>>> cancelUserBooking(
            @PathVariable Long bookingId,
            @RequestBody(required = false) CancelBookingRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        bookingService.cancelUserBooking(bookingId, request, currentUser);

        Map<String, String> response = new HashMap<>();
        response.put("message", "Hủy booking thành công");
        response.put("bookingId", bookingId.toString());

        return ResponseEntity.ok(
                APIResponse.<Map<String, String>>builder()
                        .msg("Hủy booking thành công")
                        .data(response)
                        .build()
        );
    }

    /**
     * GET /api/v1/bookings/find-by-qr?qr={qrData}
     * Tìm booking bằng mã QR
     */
    @GetMapping("/find-by-qr")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<UserBookingResponse>> findBookingByQR(
            @RequestParam String qr,
            @AuthenticationPrincipal User currentUser
    ) {
        UserBookingResponse booking = bookingService.findBookingByQR(qr, currentUser);
        return ResponseEntity.ok(
                APIResponse.<UserBookingResponse>builder()
                        .msg("Tìm thấy booking")
                        .data(booking)
                        .build()
        );
    }
    /**
     * GET /api/v1/bookings/user/cancellation-policy/{bookingId}
     * Lấy thông tin chính sách hủy trước khi hủy
     */
    @GetMapping("/user/cancellation-policy/{bookingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<APIResponse<CancellationPolicyResponse>> getCancellationPolicy(
            @PathVariable Long bookingId,
            @AuthenticationPrincipal User currentUser
    ) {
        CancellationPolicyResponse policy = bookingService.getCancellationPolicy(bookingId, currentUser);
        return ResponseEntity.ok(
                APIResponse.<CancellationPolicyResponse>builder()
                        .msg("Lấy thông tin chính sách hủy thành công")
                        .data(policy)
                        .build()
        );
    }
}
