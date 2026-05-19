package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.user.request.PaymentRequest;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.dto.user.response.PaymentUrlResponse;
import com.example.smart_travel_BE.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/payment")
@RequiredArgsConstructor
@Slf4j
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping("/create-online-payment")
    public ResponseEntity<APIResponse<PaymentUrlResponse>> createOnlinePayment(
            @Valid @RequestBody PaymentRequest request,
            HttpServletRequest httpServletRequest) {

        PaymentUrlResponse response = paymentService.createOnlinePayment(request, httpServletRequest);
        return ResponseEntity.ok(APIResponse.<PaymentUrlResponse>builder()
                .msg("Tạo link thanh toán thành công")
                .data(response)
                .build());
    }

    // API cho Admin xác nhận thanh toán cash
    @PostMapping("/admin-confirm-cash")
    public ResponseEntity<APIResponse<String>> adminConfirmCashPayment(
            @Valid @RequestBody PaymentRequest request,
            @RequestParam Long adminId) {

        String bookingId = paymentService.confirmCashPayment(request, adminId, "ADMIN");
        return ResponseEntity.ok(APIResponse.<String>builder()
                .msg("Admin xác nhận thanh toán tiền mặt thành công")
                .data("Booking ID: " + bookingId)
                .build());
    }

    // API cho Homestay xác nhận thanh toán cash
    @PostMapping("/homestay-confirm-cash")
    public ResponseEntity<APIResponse<String>> homestayConfirmCashPayment(
            @Valid @RequestBody PaymentRequest request,
            @RequestParam Long homestayId) {

        String bookingId = paymentService.confirmCashPayment(request, homestayId, "HOMESTAY");
        return ResponseEntity.ok(APIResponse.<String>builder()
                .msg("Homestay xác nhận đã nhận tiền mặt thành công")
                .data("Booking ID: " + bookingId)
                .build());
    }

    // API chung cho FE - tự động detect role từ currentUser
    @PostMapping("/confirm-cash-payment")
    public ResponseEntity<APIResponse<String>> confirmCashPayment(
            @Valid @RequestBody PaymentRequest request) {

        // Lấy user hiện tại từ SecurityContext (Spring Security sẽ inject)
        // Nếu đây là guest user, thì status là PENDING
        // Nếu là host/admin, thì xác nhận ngay
        String bookingId = paymentService.confirmCashPayment(request, request.getUserId(), "GUEST");
        return ResponseEntity.ok(APIResponse.<String>builder()
                .msg("Đặt nước homestay thành công! Sẽ thanh toán sau")
                .data("Booking ID: " + bookingId)
                .build());
    }

    @GetMapping("/vnpay-return")
    public void vnpayReturn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String resultMsg = paymentService.handleVnPayReturn(request);
            String vnp_TxnRef = request.getParameter("vnp_TxnRef");
            String deepLink = "smarttravel://payment-result?status=success&paymentId=" + vnp_TxnRef;
            response.sendRedirect(deepLink);
        } catch (Exception e) {
            response.sendRedirect("smarttravel://payment-result?status=failed&msg=" + e.getMessage());
        }
    }

    @GetMapping("/momo-return")
    public ResponseEntity<APIResponse<String>> momoReturn(@RequestParam Map<String, String> params) {
        log.info("Khách hàng đã quay về từ MoMo");
        String message = paymentService.handleMoMoReturn(params);
        return ResponseEntity.ok(APIResponse.<String>builder()
                .msg("Thanh toán MoMo thành công")
                .data(message)
                .build());
    }

    @PostMapping("/momo-ipn")
    public ResponseEntity<APIResponse<String>> momoIpn(@RequestBody Map<String, Object> ipnData) {
        log.info("MoMo IPN received: {}", ipnData);
        // Xử lý IPN nếu cần
        return ResponseEntity.ok(APIResponse.<String>builder()
                .msg("IPN processed successfully")
                .build());
    }
}