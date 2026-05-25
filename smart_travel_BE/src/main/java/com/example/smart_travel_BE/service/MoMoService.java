package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.config.MoMoConfig;
import com.example.smart_travel_BE.entity.Booking;
import com.example.smart_travel_BE.entity.CommissionStatus;
import com.example.smart_travel_BE.entity.Invoice;
import com.example.smart_travel_BE.entity.Payment;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.BookingRepository;
import com.example.smart_travel_BE.repository.InvoiceRepository;
import com.example.smart_travel_BE.repository.PaymentRepository;
import com.example.smart_travel_BE.repository.SystemConfigRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class MoMoService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final PaymentRepository paymentRepository;
    private final BookingRepository bookingRepository;
    private final InvoiceRepository invoiceRepository;
    private final SystemConfigRepository systemConfigRepository;

    public String createPaymentUrl(Payment payment, HttpServletRequest httpServletRequest) {
        long amount = payment.getAmount().longValue();

        String orderId = payment.getId() + "_" + System.currentTimeMillis();

        String requestId = UUID.randomUUID().toString();

        String partnerCode = MoMoConfig.PARTNER_CODE;
        String accessKey = MoMoConfig.ACCESS_KEY;
        String secretKey = MoMoConfig.SECRET_KEY;
        String returnUrl = MoMoConfig.REDIRECT_URL;
        String ipnUrl = MoMoConfig.IPN_URL;
        String orderInfo = "Thanh toan don hang Booking " + payment.getBooking().getId();
        String requestType = "captureWallet";
        String extraData = "";

        // Tạo rawSignature
        String rawSignature = "accessKey=" + accessKey +
                "&amount=" + amount +
                "&extraData=" + extraData +
                "&ipnUrl=" + ipnUrl +
                "&orderId=" + orderId +
                "&orderInfo=" + orderInfo +
                "&partnerCode=" + partnerCode +
                "&redirectUrl=" + returnUrl +
                "&requestId=" + requestId +
                "&requestType=" + requestType;

        // Ký chữ ký
        String signature = MoMoConfig.signHmacSHA256(rawSignature, secretKey);

        // Tạo body request
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("partnerCode", partnerCode);
        requestBody.put("accessKey", accessKey);
        requestBody.put("requestId", requestId);
        requestBody.put("amount", amount);
        requestBody.put("orderId", orderId);
        requestBody.put("orderInfo", orderInfo);
        requestBody.put("redirectUrl", returnUrl);
        requestBody.put("ipnUrl", ipnUrl);
        requestBody.put("requestType", requestType);
        requestBody.put("extraData", extraData);
        requestBody.put("signature", signature);
        requestBody.put("lang", "vi");
        requestBody.put("storeId", "SmartTravelBE");

        // Gửi request
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            String responseJson = restTemplate.postForObject(MoMoConfig.MOMO_API_URL, entity, String.class);
            Map<String, Object> responseMap = objectMapper.readValue(responseJson, Map.class);

            System.out.println("MoMo Response: " + responseJson);

            String payUrl = (String) responseMap.get("payUrl");
            String resultCode = String.valueOf(responseMap.get("resultCode"));

            if ("0".equals(resultCode) && payUrl != null) {
                return payUrl;

            } else {
                throw new AppException(ErrorCode.MOMO_CREATE_PAYMENT_FAILED);
            }
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Lỗi xử lý JSON từ MoMo", e);
        } catch (Exception e) {
            throw new AppException(ErrorCode.MOMO_API_CALL_FAILED);
        }
    }

    @Transactional
    public String handleMoMoReturn(Map<String, String> params) {
        try {
            String orderId = params.get("orderId");
            String resultCode = params.get("resultCode");

            if (orderId == null || orderId.isEmpty()) {
                log.error("MoMo return: orderId is missing");
                throw new AppException(ErrorCode.PAYMENT_NOT_FOUND);
            }

            // Payment ID is the first part before "_"
            String[] orderParts = orderId.split("_");
            if (orderParts.length < 1) {
                log.error("MoMo return: Invalid orderId format: {}", orderId);
                throw new AppException(ErrorCode.PAYMENT_NOT_FOUND);
            }

            long paymentId = Long.parseLong(orderParts[0]);
            Payment payment = paymentRepository.findById(paymentId)
                    .orElseThrow(() -> {
                        log.error("MoMo return: Payment not found. PaymentId: {}", paymentId);
                        return new AppException(ErrorCode.PAYMENT_NOT_FOUND);
                    });

            // Check if payment is already processed
            if ("PAID".equals(payment.getStatus())) {
                log.warn("MoMo return: Payment already processed. PaymentId: {}", paymentId);
                return "Giao dịch đã hoàn tất trước đó.";
            }

            // Check result code from MoMo (0 = success)
            if ("0".equals(resultCode)) {
                payment.setStatus("PAID");
                payment.setPaidAt(LocalDateTime.now());
                payment.setTransactionId(params.get("transId"));
                paymentRepository.save(payment);

                Booking booking = payment.getBooking();
                booking.setStatus("ACTIVE");
                bookingRepository.save(booking);

                // Create invoice if not exists
                Invoice invoice = invoiceRepository.findByBooking_Id(booking.getId()).orElse(null);
                if (invoice == null) {
                    invoice = createInvoiceForMoMoPayment(booking);
                    invoiceRepository.save(invoice);
                }

                log.info("MoMo payment successful. PaymentId: {}, BookingId: {}", paymentId, booking.getId());
                return "Thanh toán MoMo thành công!";
            } else {
                // Payment failed
                payment.setStatus("FAILED");
                payment.setNote("MoMo payment failed with result code: " + resultCode);
                paymentRepository.save(payment);

                log.warn("MoMo payment failed. PaymentId: {}, ResultCode: {}", paymentId, resultCode);
                return "Thanh toán MoMo thất bại!";
            }
        } catch (NumberFormatException e) {
            log.error("MoMo return: Invalid payment ID format", e);
            throw new AppException(ErrorCode.PAYMENT_NOT_FOUND);
        } catch (Exception e) {
            log.error("MoMo return: Error processing payment", e);
            throw new AppException(ErrorCode.PAYMENT_NOT_FOUND);
        }
    }

    private Invoice createInvoiceForMoMoPayment(Booking booking) {
        // Lấy cấu hình hệ thống
        var config = systemConfigRepository.findFirstConfig().orElse(null);

        Invoice invoice = new Invoice();
        invoice.setBooking(booking);
        invoice.setInvoiceNumber("INV-MOMO-" + booking.getId() + "-" + System.currentTimeMillis());
        invoice.setTotalAmount(booking.getFinalPrice());

        if (config != null) {
            BigDecimal taxAmount = config.getTaxRate() != null 
                    ? booking.getFinalPrice()
                    .multiply(config.getTaxRate())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            BigDecimal commissionAmount = config.getCommissionRate() != null
                    ? booking.getFinalPrice()
                    .multiply(config.getCommissionRate())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            invoice.setTaxAmount(taxAmount);
            invoice.setCommissionPercentage(config.getCommissionRate());
            invoice.setCommissionAmount(commissionAmount);
            invoice.setHomestayAmount(booking.getFinalPrice().subtract(commissionAmount));
            invoice.setCommissionStatus(CommissionStatus.PENDING);
        }

        invoice.setIssueDate(LocalDate.now());
        invoice.setItemDetails("{\"note\": \"Invoice created via MoMo Return\"}");
        invoice.setReviewed(false);
        invoice.setCreatedAt(LocalDateTime.now());

        return invoice;
    }
}