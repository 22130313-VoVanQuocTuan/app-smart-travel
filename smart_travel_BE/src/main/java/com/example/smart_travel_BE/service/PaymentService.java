package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.user.request.PaymentRequest;
import com.example.smart_travel_BE.dto.user.response.PaymentUrlResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.*;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;

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


    @Transactional
    public PaymentUrlResponse createOnlinePayment(PaymentRequest request, HttpServletRequest httpServletRequest) {

        // 1. Tạo booking từ request (chưa có bookingId)
        Booking booking = createBookingFromRequest(request);
        booking = bookingRepository.save(booking);

        // 2. Tạo payment
        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setAmount(calculateTotalAmount(request));
        payment.setPaymentMethod(request.getPaymentMethod().toUpperCase());
        payment.setStatus("PENDING");
        payment.setPayment_status("PENDING");
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


    @Transactional
    public String confirmCashPayment(PaymentRequest request) {

        // 1. Tạo booking từ request
        Booking booking = createBookingFromRequest(request);
        booking.setStatus("CONFIRMED"); // Đặt thành công, thanh toán sau
        booking = bookingRepository.save(booking);

        // 2. Tạo payment (thanh toán tiền mặt)
        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setAmount(calculateTotalAmount(request));
        payment.setPaymentMethod("CASH");
        payment.setStatus("COMPLETED");
        payment.setPayment_status("DONE");
        payment.setPaidAt(LocalDateTime.now());
        payment.setCreatedAt(LocalDateTime.now());
        payment.setUpdatedAt(LocalDateTime.now());
        paymentRepository.save(payment);

        // 3. Tạo invoice
        Invoice invoice = new Invoice();
        invoice.setBooking(booking);
        invoice.setInvoiceNumber("INV-CASH-" + booking.getId() + "-" + System.currentTimeMillis());
        invoice.setTotalAmount(booking.getFinalPrice());
        invoice.setTaxAmount(BigDecimal.ZERO);
        invoice.setIssueDate(LocalDate.now());
        invoice.setItemDetails("{\"note\": \"Thanh toán tiền mặt tại homestay\"}");
        invoice.setReviewed(false);
        invoiceRepository.save(invoice);

        return booking.getId().toString();
    }


    private Booking createBookingFromRequest(PaymentRequest request) {

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        // Tính tiền phòng
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
        for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
            tourTotal = tourTotal.add(tourReq.getPricePerPerson()
                    .multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
        }

        BigDecimal totalPrice = roomTotal.add(tourTotal);
        BigDecimal finalPrice = totalPrice.subtract(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO);
        if (finalPrice.compareTo(BigDecimal.ZERO) < 0) finalPrice = BigDecimal.ZERO;

        // Tạo booking
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

        return booking;
    }

    private BigDecimal calculateTotalAmount(PaymentRequest request) {
        // Tính lại tổng tiền để kiểm tra (có thể không cần nếu đã tính ở booking)
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
        for (PaymentRequest.TourBookingRequest tourReq : request.getTours()) {
            tourTotal = tourTotal.add(tourReq.getPricePerPerson()
                    .multiply(BigDecimal.valueOf(tourReq.getNumberOfPeople())));
        }

        BigDecimal total = roomTotal.add(tourTotal);
        if (request.getDiscountAmount() != null) {
            total = total.subtract(request.getDiscountAmount());
        }
        return total.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : total;
    }

    @Transactional
    public String handleVnPayReturn(HttpServletRequest request) {
        String vnp_TxnRef = request.getParameter("vnp_TxnRef");

        if (vnp_TxnRef == null) {
            throw new AppException(ErrorCode.PAYMENT_NOT_FOUND); // Hoặc return lỗi
        }

        Payment payment = paymentRepository.findById(Long.parseLong(vnp_TxnRef))
                .orElseThrow(() -> new AppException(ErrorCode.PAYMENT_NOT_FOUND));

        if ("COMPLETED".equals(payment.getStatus())) {
            return "Giao dịch đã hoàn tất trước đó.";
        }

        payment.setStatus("COMPLETED");
        payment.setPayment_status("DONE");
        payment.setPaidAt(LocalDateTime.now());
        String transactionNo = request.getParameter("vnp_TransactionNo");
        payment.setTransactionId(transactionNo != null ? transactionNo : "TEST_TRANS_ID");

        paymentRepository.save(payment);
        Booking booking = payment.getBooking();
        booking.setStatus("ACTIVE");
        bookingRepository.save(booking);

        Invoice invoice = invoiceRepository.findByBooking_Id(booking.getId()).orElse(null);
        if (invoice == null) {
            invoice = new Invoice();
            invoice.setBooking(booking);
            invoice.setInvoiceNumber("INV-VNPAY-" + booking.getId() + "-" + System.currentTimeMillis());
            invoice.setTotalAmount(booking.getFinalPrice());
            invoice.setTaxAmount(BigDecimal.ZERO);
            invoice.setIssueDate(LocalDate.now());
            invoice.setItemDetails("{\"note\": \"Invoice created via VNPay Return (Auto-Success Mode)\"}");
            invoice.setReviewed(false);
            invoiceRepository.save(invoice);
        }

        return "Thanh toán VNPay thành công (Chế độ Test)!";
    }

    @Transactional
    public String handleMoMoReturn(Map<String, String> params) {
        return moMoService.handleMoMoReturn(params);
    }

}