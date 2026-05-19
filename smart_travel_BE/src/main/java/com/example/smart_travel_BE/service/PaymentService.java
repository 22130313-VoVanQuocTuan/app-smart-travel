package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.user.request.PaymentRequest;
import com.example.smart_travel_BE.dto.user.response.PaymentUrlResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.entity.CommissionStatus;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final BookingRepository bookingRepository;
    private final PaymentRepository paymentRepository;
    private final VnPayService vnPayService;
    private final MoMoService moMoService;
    private final InvoiceRepository invoiceRepository;
    private final TourRepository tourRepository;
    private final BookingTourRepository bookingTourRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final HomestayRepository homestayRepository;
    private final UserRepository userRepository;
    private final SystemConfigRepository systemConfigRepository;

    // ==================== ONLINE PAYMENT ====================
    @Transactional
    public PaymentUrlResponse createOnlinePayment(PaymentRequest request, HttpServletRequest httpServletRequest) {

        // 1. Tạo booking từ request
        Booking booking = createBookingFromRequest(request);
        booking = bookingRepository.save(booking);

        // 2. Tạo payment
        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setAmount(calculateTotalAmount(request));
        payment.setPaymentMethod(request.getPaymentMethod().toUpperCase());
        payment.setStatus("PENDING");
        payment.setCreatedAt(LocalDateTime.now());
        payment.setUpdatedAt(LocalDateTime.now());
        payment = paymentRepository.save(payment);

        // 3. Tạo link thanh toán
        String paymentUrl;
        if ("VNPAY".equalsIgnoreCase(request.getPaymentMethod())) {
            paymentUrl = vnPayService.createPaymentUrl(payment, httpServletRequest);
        } else if ("MOMO".equalsIgnoreCase(request.getPaymentMethod())) {
            paymentUrl = moMoService.createPaymentUrl(payment, httpServletRequest);
        } else {
            throw new AppException(ErrorCode.PAYMENT_METHOD_NOT_SUPPORTED);
        }

        return new PaymentUrlResponse(paymentUrl);
    }

    // ==================== CASH PAYMENT ====================
    @Transactional
    public String confirmCashPayment(PaymentRequest request, Long confirmedById, String confirmedRole) {

        // 1. Lấy cấu hình hệ thống
        SystemConfig config = systemConfigRepository.findFirstConfig()
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        // 2. Lấy thông tin user
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        // 3. Kiểm tra tính hợp lệ
        validateBookingRequest(request);

        // 4. Tạo booking
        Booking booking = createBookingFromRequest(request, user);
        booking.setStatus("CONFIRMED");
        booking = bookingRepository.save(booking);

        // 4.5. Tạo booking tours nếu có
        if (request.getTours() != null && !request.getTours().isEmpty()) {
            for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
                Tour tour = tourRepository.findById(tourReq.getTourId())
                        .orElseThrow(() -> new AppException(ErrorCode.TOUR_NOT_FOUND));

                BookingTour bookingTour = new BookingTour();
                bookingTour.setBooking(booking);
                bookingTour.setTour(tour);
                bookingTour.setTourDate(tourReq.getTourDate());
                bookingTour.setNumberOfPeople(tourReq.getNumberOfPeople());
                bookingTour.setUnitPrice(tourReq.getPricePerPerson());
                bookingTour.setTotalPrice(tourReq.getPricePerPerson().multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
                bookingTour.setStatus("PENDING");
                bookingTour.setCreatedAt(LocalDateTime.now());
                bookingTourRepository.save(bookingTour);
            }
        }

        // 5. Tạo payment
        Payment payment = createPayment(booking, request, confirmedById, confirmedRole);
        paymentRepository.save(payment);

        // 6. Tạo invoice
        Invoice invoice = createInvoice(booking, config, request, confirmedById, confirmedRole);
        invoiceRepository.save(invoice);

        log.info("Thanh toán tiền mặt thành công cho booking ID: {}", booking.getId());

        return booking.getId().toString();
    }

    // ==================== VALIDATION ====================
    private void validateBookingRequest(PaymentRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new AppException(ErrorCode.INVALID_DATE_RANGE);
        }

        if (request.getNumberOfPeople() <= 0) {
            throw new AppException(ErrorCode.INVALID_NUMBER_OF_PEOPLE);
        }

        if (request.getNumberOfRooms() < 0) {
            throw new AppException(ErrorCode.INVALID_NUMBER_OF_ROOMS);
        }

        if (request.getRoomTypeId() != null) {
            RoomType roomType = roomTypeRepository.findById(request.getRoomTypeId())
                    .orElseThrow(() -> new AppException(ErrorCode.ROOM_TYPE_NOT_FOUND));

            if (roomType.getAvailableRooms() < request.getNumberOfRooms()) {
                throw new AppException(ErrorCode.NOT_ENOUGH_ROOMS);
            }
        }
    }

    // ==================== CREATE BOOKING ====================
    private Booking createBookingFromRequest(PaymentRequest request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Homestay homestay = homestayRepository.findById(request.getHomestayId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        RoomType roomType = null;
        if (request.getRoomTypeId() != null) {
            roomType = roomTypeRepository.findById(request.getRoomTypeId())
                    .orElseThrow(() -> new AppException(ErrorCode.ROOM_TYPE_NOT_FOUND));
        }

        long nights = java.time.temporal.ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate());
        if (nights < 1) nights = 1;

        BigDecimal roomTotal = BigDecimal.ZERO;
        if (roomType != null) {
            roomTotal = roomType.getPrice()
                    .multiply(BigDecimal.valueOf(request.getNumberOfRooms()))
                    .multiply(BigDecimal.valueOf(nights));
        }

        // Tính tiền tour
        BigDecimal tourTotal = BigDecimal.ZERO;
        if (request.getTours() != null) {
            for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
                tourTotal = tourTotal.add(tourReq.getPricePerPerson()
                        .multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
            }
        }

        BigDecimal totalPrice = roomTotal.add(tourTotal);
        BigDecimal finalPrice = totalPrice.subtract(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO);
        if (finalPrice.compareTo(BigDecimal.ZERO) < 0) finalPrice = BigDecimal.ZERO;

        Booking booking = new Booking();
        booking.setUser(user);
        booking.setBookingType("HOMESTAY");
        booking.setHotelId(request.getHomestayId());
        booking.setRoomType(roomType);
        booking.setStartDate(request.getStartDate());
        booking.setEndDate(request.getEndDate());
        booking.setNumberOfPeople(request.getNumberOfPeople());
        booking.setNumberOfRooms(request.getNumberOfRooms());
        booking.setCouponCode(request.getCouponCode());
        booking.setTotalPrice(totalPrice);
        booking.setDiscountAmount(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO);
        booking.setFinalPrice(finalPrice);
        booking.setStatus("PENDING");
        booking.setCreatedAt(LocalDateTime.now());
        booking.setUpdatedAt(LocalDateTime.now());

        booking = bookingRepository.save(booking);

        // Tạo booking tours
        if (request.getTours() != null) {
            for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
                Tour tour = tourRepository.findById(tourReq.getTourId())
                        .orElseThrow(() -> new AppException(ErrorCode.TOUR_NOT_FOUND));

                BookingTour bookingTour = new BookingTour();
                bookingTour.setBooking(booking);
                bookingTour.setTour(tour);
                bookingTour.setTourDate(tourReq.getTourDate());
                bookingTour.setNumberOfPeople(tourReq.getNumberOfPeople());
                bookingTour.setUnitPrice(tourReq.getPricePerPerson());
                bookingTour.setTotalPrice(tourReq.getPricePerPerson().multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
                bookingTour.setStatus("PENDING");
                bookingTour.setCreatedAt(LocalDateTime.now());
                bookingTourRepository.save(bookingTour);
            }
        }

        return booking;
    }

    private Booking createBookingFromRequest(PaymentRequest request, User user) {
        Homestay homestay = homestayRepository.findById(request.getHomestayId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        RoomType roomType = null;
        if (request.getRoomTypeId() != null) {
            roomType = roomTypeRepository.findById(request.getRoomTypeId())
                    .orElseThrow(() -> new AppException(ErrorCode.ROOM_TYPE_NOT_FOUND));
        }

        long nights = java.time.temporal.ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate());
        if (nights < 1) nights = 1;

        BigDecimal roomTotal = BigDecimal.ZERO;
        if (roomType != null) {
            roomTotal = roomType.getPrice()
                    .multiply(BigDecimal.valueOf(request.getNumberOfRooms()))
                    .multiply(BigDecimal.valueOf(nights));
        }

        BigDecimal tourTotal = BigDecimal.ZERO;
        if (request.getTours() != null) {
            for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
                tourTotal = tourTotal.add(tourReq.getPricePerPerson()
                        .multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
            }
        }

        BigDecimal totalPrice = roomTotal.add(tourTotal);
        BigDecimal finalPrice = totalPrice.subtract(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO);
        if (finalPrice.compareTo(BigDecimal.ZERO) < 0) finalPrice = BigDecimal.ZERO;

        return Booking.builder()
                .user(user)
                .bookingType("HOMESTAY")
                .hotelId(request.getHomestayId())
                .roomType(roomType)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .numberOfPeople(request.getNumberOfPeople())
                .numberOfRooms(request.getNumberOfRooms())
                .totalPrice(totalPrice)
                .discountAmount(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO)
                .finalPrice(finalPrice)
                .couponCode(request.getCouponCode())
                .status("CONFIRMED")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    // ==================== CREATE PAYMENT ====================
    private Payment createPayment(Booking booking, PaymentRequest request, Long confirmedById, String confirmedRole) {
        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setAmount(booking.getFinalPrice());
        payment.setPaymentMethod(request.getPaymentMethod());

        if ("ADMIN".equals(confirmedRole)) {
            payment.setStatus("PAID");
            payment.setNote("Admin " + confirmedById + " xác nhận thanh toán tiền mặt");
        } else if ("HOST".equals(confirmedRole)) {
            payment.setStatus("PAID_AT_HOMESTAY");
            payment.setNote("Homestay " + confirmedById + " xác nhận đã nhận tiền mặt trực tiếp");
        } else {
            payment.setStatus("PENDING");
            payment.setNote("Chờ xác nhận thanh toán tiền mặt");
        }

        payment.setPaidAt(LocalDateTime.now());
        payment.setCreatedAt(LocalDateTime.now());
        payment.setUpdatedAt(LocalDateTime.now());

        return payment;
    }

    // ==================== CREATE INVOICE ====================
    private Invoice createInvoice(Booking booking, SystemConfig config,
                                  PaymentRequest request, Long confirmedById, String confirmedRole) {

        BigDecimal totalAmount = booking.getFinalPrice();
        BigDecimal taxRate = config.getTaxRate() != null ? config.getTaxRate() : BigDecimal.ZERO;
        BigDecimal commissionRate = config.getCommissionRate() != null ? config.getCommissionRate() : BigDecimal.ZERO;

        BigDecimal taxAmount = calculateTax(totalAmount, taxRate);
        BigDecimal commissionAmount = totalAmount
                .multiply(commissionRate)
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal homestayAmount = totalAmount.subtract(commissionAmount);

        String itemDetails = buildItemDetails(request, confirmedById, confirmedRole, booking);

        Invoice invoice = new Invoice();
        invoice.setBooking(booking);
        invoice.setInvoiceNumber(generateInvoiceNumber(booking.getId(), "CASH"));
        invoice.setTotalAmount(totalAmount);
        invoice.setTaxAmount(taxAmount);
        invoice.setItemDetails(itemDetails);
        invoice.setIssueDate(LocalDate.now());
        invoice.setReviewed(false);
        invoice.setCommissionPercentage(commissionRate);
        invoice.setCommissionAmount(commissionAmount);
        invoice.setHomestayAmount(homestayAmount);
        invoice.setCommissionStatus(CommissionStatus.PENDING);
        invoice.setCreatedAt(LocalDateTime.now());

        return invoice;
    }

    // ==================== CALCULATIONS ====================
    private BigDecimal calculateTotalAmount(PaymentRequest request) {
        long nights = java.time.temporal.ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate());
        if (nights < 1) nights = 1;

        BigDecimal roomTotal = BigDecimal.ZERO;
        if (request.getRoomTypeId() != null) {
            RoomType roomType = roomTypeRepository.findById(request.getRoomTypeId())
                    .orElseThrow(() -> new AppException(ErrorCode.ROOM_TYPE_NOT_FOUND));
            roomTotal = roomType.getPrice()
                    .multiply(BigDecimal.valueOf(request.getNumberOfRooms()))
                    .multiply(BigDecimal.valueOf(nights));
        }

        BigDecimal tourTotal = BigDecimal.ZERO;
        if (request.getTours() != null) {
            for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
                tourTotal = tourTotal.add(tourReq.getPricePerPerson()
                        .multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
            }
        }

        BigDecimal total = roomTotal.add(tourTotal);
        if (request.getDiscountAmount() != null) {
            total = total.subtract(request.getDiscountAmount());
        }
        return total.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : total;
    }

    private BigDecimal calculateTax(BigDecimal amount, BigDecimal taxRate) {
        return taxRate == null ? BigDecimal.ZERO
                : amount.multiply(taxRate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    // ==================== UTILITIES ====================
    private String buildItemDetails(PaymentRequest request, Long confirmedById,
                                    String confirmedRole, Booking booking) {
        try {
            Map<String, Object> details = new HashMap<>();
            details.put("payment_method", request.getPaymentMethod());
            details.put("confirmed_by", confirmedById);
            details.put("confirmed_role", confirmedRole);
            details.put("confirmed_at", LocalDateTime.now().toString());
            details.put("homestay_id", request.getHomestayId());
            details.put("room_type_id", request.getRoomTypeId());
            details.put("number_of_rooms", request.getNumberOfRooms());
            details.put("number_of_people", request.getNumberOfPeople());
            details.put("start_date", request.getStartDate().toString());
            details.put("end_date", request.getEndDate().toString());

            if (request.getCouponCode() != null) {
                details.put("coupon_code", request.getCouponCode());
            }

            if (request.getDiscountAmount() != null) {
                details.put("discount_amount", request.getDiscountAmount());
            }

            if (request.getTours() != null && !request.getTours().isEmpty()) {
                details.put("tours", request.getTours());
            }

            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(details);
        } catch (Exception e) {
            return "{\"note\": \"Thanh toán tiền mặt\"}";
        }
    }

    private String generateInvoiceNumber(Long bookingId, String type) {
        return "INV-" + type + "-" + bookingId + "-" + System.currentTimeMillis();
    }

    // ==================== PAYMENT RETURN HANDLERS ====================
    @Transactional
    public String handleVnPayReturn(HttpServletRequest request) {
        String vnp_TxnRef = request.getParameter("vnp_TxnRef");

        if (vnp_TxnRef == null) {
            throw new AppException(ErrorCode.PAYMENT_NOT_FOUND);
        }

        Payment payment = paymentRepository.findById(Long.parseLong(vnp_TxnRef))
                .orElseThrow(() -> new AppException(ErrorCode.PAYMENT_NOT_FOUND));

        if ("COMPLETED".equals(payment.getStatus())) {
            return "Giao dịch đã hoàn tất trước đó.";
        }

        payment.setStatus("COMPLETED");
        payment.setPaidAt(LocalDateTime.now());
        String transactionNo = request.getParameter("vnp_TransactionNo");
        payment.setTransactionId(transactionNo != null ? transactionNo : "TEST_TRANS_ID");
        paymentRepository.save(payment);

        Booking booking = payment.getBooking();
        booking.setStatus("ACTIVE");
        bookingRepository.save(booking);

        // Lấy cấu hình để tạo invoice
        SystemConfig config = systemConfigRepository.findFirstConfig()
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        Invoice invoice = invoiceRepository.findByBooking_Id(booking.getId()).orElse(null);
        if (invoice == null) {
            invoice = new Invoice();
            invoice.setBooking(booking);
            invoice.setInvoiceNumber("INV-VNPAY-" + booking.getId() + "-" + System.currentTimeMillis());
            invoice.setTotalAmount(booking.getFinalPrice());

            // Tính thuế và hoa hồng
            BigDecimal taxAmount = calculateTax(booking.getFinalPrice(), config.getTaxRate());
            BigDecimal commissionAmount = booking.getFinalPrice()
                    .multiply(config.getCommissionRate())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

            invoice.setTaxAmount(taxAmount);
            invoice.setCommissionPercentage(config.getCommissionRate());
            invoice.setCommissionAmount(commissionAmount);
            invoice.setHomestayAmount(booking.getFinalPrice().subtract(commissionAmount));
            invoice.setCommissionStatus(CommissionStatus.PENDING);
            invoice.setIssueDate(LocalDate.now());
            invoice.setItemDetails("{\"note\": \"Invoice created via VNPay Return\"}");
            invoice.setReviewed(false);
            invoice.setCreatedAt(LocalDateTime.now());
            invoiceRepository.save(invoice);
        }

        return "Thanh toán VNPay thành công!";
    }

    @Transactional
    public String handleMoMoReturn(Map<String, String> params) {
        return moMoService.handleMoMoReturn(params);
    }
}