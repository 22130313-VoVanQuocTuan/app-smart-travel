package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.invoice.request.CancelOrderRequest;
import com.example.smart_travel_BE.dto.invoice.request.CheckInRequest;
import com.example.smart_travel_BE.dto.invoice.request.CheckOutRequest;
import com.example.smart_travel_BE.dto.invoice.request.RefundApprovalRequest;
import com.example.smart_travel_BE.dto.invoice.request.RefundRequest;
import com.example.smart_travel_BE.dto.invoice.response.ActiveInvoiceResponse;
import com.example.smart_travel_BE.dto.invoice.response.AdminInvoiceDetailResponse;
import com.example.smart_travel_BE.dto.invoice.response.AdminInvoiceResponse;
import com.example.smart_travel_BE.dto.invoice.response.InvoiceDetailResponse;
import com.example.smart_travel_BE.entity.Booking;
import com.example.smart_travel_BE.entity.CommissionStatus;
import com.example.smart_travel_BE.entity.Homestay;
import com.example.smart_travel_BE.entity.Invoice;
import com.example.smart_travel_BE.entity.Payment;
import com.example.smart_travel_BE.entity.SystemConfig;
import com.example.smart_travel_BE.entity.User;
import com.example.smart_travel_BE.entity.UserProfile;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.mapper.InvoiceDetailMapper;
import com.example.smart_travel_BE.mapper.InvoiceMapper;
import com.example.smart_travel_BE.repository.BookingRepository;
import com.example.smart_travel_BE.repository.InvoiceRepository;
import com.example.smart_travel_BE.repository.SystemConfigRepository;
import com.example.smart_travel_BE.repository.UserProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final BookingRepository bookingRepository;
    private final InvoiceMapper invoiceMapper;
    private final InvoiceDetailMapper invoiceDetailMapper;
    private final UserProfileRepository userProfileRepository;
    private final SystemConfigRepository systemConfigRepository;
    private final EmailService emailService;

    @Value("${app.notifications.refund.admin-emails:}")
    private String refundAdminEmails;

    public List<ActiveInvoiceResponse> getActiveInvoices() {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.findActiveInvoicesByUserId(curUser.getId());
        return bookings.stream()
                .map(invoiceMapper::toActiveResponse)
                .toList();
    }

    public List<ActiveInvoiceResponse> getRefundedInvoices() {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.findRefundedInvoices(curUser.getId());
        return bookings.stream().map(invoiceMapper::toActiveResponse).toList();
    }

    public List<ActiveInvoiceResponse> getReviewableInvoices() {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.findReviewableInvoices(curUser.getId());
        return bookings.stream().map(invoiceMapper::toActiveResponse).toList();
    }

    public List<ActiveInvoiceResponse> searchActiveInvoices(String keyword) {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.searchActiveInvoices(curUser.getId(), keyword);
        return bookings.stream().map(invoiceMapper::toActiveResponse).toList();
    }

    public List<ActiveInvoiceResponse> searchRefundedInvoices(String keyword) {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.searchRefundedInvoices(curUser.getId(), keyword);
        return bookings.stream().map(invoiceMapper::toActiveResponse).toList();
    }

    public InvoiceDetailResponse getInvoiceDetailFull(Long bookingId) {
        Booking booking = invoiceRepository.findFullBookingById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));
        return invoiceDetailMapper.toDetailResponse(booking);
    }

    @Transactional
    public void requestRefund(RefundRequest request) {
        User currentUser = getCurrentUser();
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));
        Payment payment = booking.getPayment();
        Invoice invoice = booking.getInvoice();

        if (!booking.getUser().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        if ("PENDING_REFUND".equals(booking.getStatus())) {
            throw new AppException(ErrorCode.REFUND_ALREADY_REQUESTED);
        }
        if (payment == null || !isRefundablePaymentStatus(payment.getStatus())) {
            throw new AppException(ErrorCode.REFUND_NOT_ALLOWED);
        }
        if (invoice == null) {
            throw new AppException(ErrorCode.INVOICE_NOT_FOUND);
        }

        if (requiresRefundBankInfo(payment)) {
            validateRefundBankInfo(request);
            invoice.setRefundBankName(trimToNull(request.getRefundBankName()));
            invoice.setRefundBankBranch(trimToNull(request.getRefundBankBranch()));
            invoice.setRefundAccountNumber(trimToNull(request.getRefundAccountNumber()));
            invoice.setRefundAccountHolder(trimToNull(request.getRefundAccountHolder()));
        } else {
            invoice.setRefundBankName(null);
            invoice.setRefundBankBranch(null);
            invoice.setRefundAccountNumber(null);
            invoice.setRefundAccountHolder(null);
        }

        invoice.setRefundRequestedAt(LocalDateTime.now());
        invoice.setRefundApprovedAt(null);

        booking.setStatus("PENDING_REFUND");
        booking.setCancellationReason(request.getReason().trim());

        invoiceRepository.save(invoice);
        bookingRepository.save(booking);

        sendRefundRequestedNotifications(booking, invoice, payment);
    }

    public List<ActiveInvoiceResponse> getTransactionHistory(String typeFilter, String statusFilter) {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.findTransactionHistory(
                curUser.getId(),
                typeFilter != null && !typeFilter.isEmpty() ? typeFilter.toUpperCase() : null,
                statusFilter != null && !statusFilter.isEmpty() ? normalizeStatusFilter(statusFilter) : null
        );
        return bookings.stream().map(invoiceMapper::toActiveResponse).toList();
    }

    public List<AdminInvoiceResponse> getAdminInvoices(String invoiceNumber, String status) {
        User currentUser = getCurrentUser();
        String normalizedStatus = normalizeStatusFilter(status);

        List<Booking> bookings = invoiceRepository.findAdminInvoices(
                currentUser.getId(),
                currentUser.getRole(),
                invoiceNumber,
                normalizedStatus
        );

        return bookings.stream()
                .map(this::mapToAdminResponse)
                .toList();
    }

    private AdminInvoiceResponse mapToAdminResponse(Booking booking) {
        String itemName = "Dịch vụ không xác định";

        if ("HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
            Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
            String hotelName = homestay != null ? homestay.getName() : "Homestay đã xóa";
            String roomName = booking.getRoomType() != null ? " - " + booking.getRoomType().getName() : "";
            itemName = hotelName + roomName;
        }

        Invoice invoice = booking.getInvoice();

        return AdminInvoiceResponse.builder()
                .bookingId(booking.getId())
                .invoiceNumber(invoice != null ? invoice.getInvoiceNumber() : null)
                .itemName(itemName)
                .startDate(booking.getStartDate())
                .endDate(booking.getEndDate())
                .status(booking.getStatus())
                .build();
    }

    public AdminInvoiceDetailResponse getAdminInvoiceDetail(Long bookingId) {
        User currentUser = getCurrentUser();
        Booking booking = invoiceRepository.findFullBookingById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        validateManagementPermission(booking, currentUser);

        Invoice invoice = booking.getInvoice();
        Payment payment = booking.getPayment();
        String serviceName = "Dịch vụ không xác định";
        String roomTypeName = null;

        if ("HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
            Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
            serviceName = homestay != null ? homestay.getName() : "Homestay đã xóa";
            if (booking.getRoomType() != null) {
                roomTypeName = booking.getRoomType().getName();
            }
        }

        User customer = booking.getUser();
        SystemConfig config = systemConfigRepository.findFirstConfig().orElse(null);
        BigDecimal taxRate = config != null && config.getTaxRate() != null ? config.getTaxRate() : BigDecimal.ZERO;
        BigDecimal taxAmount = invoice != null && invoice.getTaxAmount() != null ? invoice.getTaxAmount() : BigDecimal.ZERO;
        BigDecimal totalWithTax = (booking.getFinalPrice() != null ? booking.getFinalPrice() : BigDecimal.ZERO)
                .add(taxAmount);

        return AdminInvoiceDetailResponse.builder()
                .bookingId(booking.getId())
                .invoiceNumber(invoice != null ? invoice.getInvoiceNumber() : null)
                .status(booking.getStatus())
                .createdAt(booking.getCreatedAt())
                .updatedAt(booking.getUpdatedAt())
                .hotelId(booking.getHotelId())
                .tourId(booking.getTourId())
                .serviceName(serviceName)
                .roomTypeName(roomTypeName)
                .startDate(booking.getStartDate())
                .endDate(booking.getEndDate())
                .numberOfPeople(booking.getNumberOfPeople())
                .numberOfRooms(booking.getNumberOfRooms())
                .specialRequests(booking.getSpecialRequests())
                .cancellationReason(booking.getCancellationReason())
                .totalPrice(booking.getTotalPrice())
                .discountAmount(booking.getDiscountAmount())
                .finalPrice(booking.getFinalPrice())
                .taxRate(taxRate)
                .totalWithTax(totalWithTax)
                .paymentStatus(payment != null ? payment.getStatus() : null)
                .paymentMethod(payment != null ? payment.getPaymentMethod() : null)
                .taxAmount(taxAmount)
                .refundBankName(invoice != null ? invoice.getRefundBankName() : null)
                .refundBankBranch(invoice != null ? invoice.getRefundBankBranch() : null)
                .refundAccountNumber(invoice != null ? invoice.getRefundAccountNumber() : null)
                .refundAccountHolder(invoice != null ? invoice.getRefundAccountHolder() : null)
                .refundRequestedAt(invoice != null ? invoice.getRefundRequestedAt() : null)
                .refundApprovedAt(invoice != null ? invoice.getRefundApprovedAt() : null)
                .customerName(customer != null ? customer.getFullName() : "Khách lẻ")
                .customerPhone(customer != null ? customer.getPhone() : null)
                .customerEmail(customer != null ? customer.getEmail() : null)
                .build();
    }

    @Transactional
    public void checkIn(CheckInRequest request) {
        User currentUser = getCurrentUser();
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));


        boolean isOwner = false;

        if ("HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
            Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
            if (homestay != null && currentUser.getId().equals(homestay.getOwner().getId())) {
                isOwner = true;
            }
        }

        if (!isOwner) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        if ("HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
            booking.setNumberOfRooms(request.getNumberOfRooms());
        }
        booking.setStatus("CHECKED");
        bookingRepository.save(booking);
    }

    @Transactional
    public void checkOut(CheckOutRequest request) {
        User currentUser = getCurrentUser();
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        if (!"CHECKED".equals(booking.getStatus())) {
            throw new AppException(ErrorCode.INVALID_STATUS);
        }
        Payment payment = booking.getPayment();
        if (payment == null || !"PAID".equals(payment.getStatus())) {
            throw new AppException(ErrorCode.PAYMENT_NOT_COMPLETED);
        }

        validateOwnerPermission(booking, currentUser);

        booking.setStatus("COMPLETED");
        booking = bookingRepository.save(booking);

        updateCommissionAfterCheckout(booking);

        User customer = booking.getUser();
        if (customer != null) {
            BigDecimal finalPrice = booking.getFinalPrice();
            long expEarned = finalPrice != null
                    ? finalPrice.divide(new BigDecimal("100000"), RoundingMode.FLOOR).longValue() * 100
                    : 0;

            if (expEarned > 0) {
                Optional<UserProfile> profileOpt = userProfileRepository.findByUser(customer);
                UserProfile profile = profileOpt.orElseGet(() -> {
                    UserProfile newProfile = UserProfile.builder()
                            .user(customer)
                            .experiencePoints(0L)
                            .darkModeEnabled(false)
                            .updatedAt(LocalDateTime.now())
                            .build();
                    return userProfileRepository.save(newProfile);
                });
                profile.setExperiencePoints(profile.getExperiencePoints() + expEarned);
                profile.setUpdatedAt(LocalDateTime.now());
                userProfileRepository.save(profile);
            }
        }
    }

    private void updateCommissionAfterCheckout(Booking booking) {
        try {
            Invoice invoice = booking.getInvoice();
            if (invoice == null) {
                log.warn("KhÃ´ng tÃ¬m tháº¥y invoice cho booking: {}", booking.getId());
                return;
            }

            SystemConfig config = systemConfigRepository.findFirstConfig()
                    .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

            BigDecimal totalAmount = booking.getFinalPrice();
            BigDecimal commissionRate = config.getCommissionRate() != null ? config.getCommissionRate() : BigDecimal.ZERO;
            BigDecimal taxRate = config.getTaxRate() != null ? config.getTaxRate() : BigDecimal.ZERO;

            BigDecimal commissionAmount = totalAmount
                    .multiply(commissionRate)
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            BigDecimal homestayAmount = totalAmount.subtract(commissionAmount);

            if (invoice.getTaxAmount() == null || invoice.getTaxAmount().compareTo(BigDecimal.ZERO) == 0) {
                BigDecimal taxAmount = totalAmount
                        .multiply(taxRate)
                        .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                invoice.setTaxAmount(taxAmount);
            }

            invoice.setCommissionPercentage(commissionRate);
            invoice.setCommissionAmount(commissionAmount);
            invoice.setHomestayAmount(homestayAmount);
            invoice.setCommissionStatus(CommissionStatus.PAID);
            invoice.setCommissionPaidAt(LocalDateTime.now());

            invoiceRepository.save(invoice);
            log.info("Đã cập nhật hoa hồng cho booking {}: commission={}, homestay={}",
                    booking.getId(), commissionAmount, homestayAmount);

        } catch (Exception e) {
            log.error("Lỗi khi cập nhật hoa hồng cho booking {}: {}", booking.getId(), e.getMessage());
        }
    }

    @Transactional
    public void cancelOrder(CancelOrderRequest request) {
        User currentUser = getCurrentUser();
        String role = currentUser.getRole();
        String fullName = currentUser.getFullName() != null ? currentUser.getFullName() : "Admin";

        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));



        boolean canCancel = false;

        if ("ADMIN".equals(role)) {
            canCancel = true;
        } else if ("HOST".equals(role)) {
            if ("HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
                Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
                if (homestay != null && currentUser.getId().equals(homestay.getOwner().getId())) {
                    canCancel = true;
                }
            }
        }

        if (!canCancel) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        String cancellationReason = String.format("%s - %s - %s", role, fullName, request.getCancelMessage());

        booking.setStatus("CANCELLED");
        booking.setCancellationReason(cancellationReason);
        bookingRepository.save(booking);
    }

    @Transactional
    public void approveRefund(RefundApprovalRequest request) {
        User currentUser = getCurrentUser();
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        if (!"PENDING_REFUND".equals(booking.getStatus())) {
            throw new AppException(ErrorCode.REFUND_NOT_PENDING);
        }

        validateManagementPermission(booking, currentUser);

        Invoice invoice = booking.getInvoice();
        if (invoice != null) {
            invoice.setRefundApprovedAt(LocalDateTime.now());
            invoiceRepository.save(invoice);
        }

        booking.setStatus("REFUNDED");
        bookingRepository.save(booking);

        sendRefundApprovedNotification(booking, invoice);
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }
        if (authentication.getPrincipal() instanceof User) {
            return (User) authentication.getPrincipal();
        }
        throw new AppException(ErrorCode.UNAUTHENTICATED);
    }

    private void validateOwnerPermission(Booking booking, User currentUser) {
        String role = currentUser.getRole();

        if ("ADMIN".equals(role)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        if (!"HOST".equals(role)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        if (!isHomestayOwner(booking, currentUser.getId())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }
    }

    private void validateManagementPermission(Booking booking, User currentUser) {
        String role = currentUser.getRole();

        if ("ADMIN".equals(role)) {
            return;
        }

        if ("HOST".equals(role) || "ADMINHOTEL".equals(role)) {
            if (isHomestayOwner(booking, currentUser.getId())) {
                return;
            }
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        if ("ADMINTOUR".equals(role) && isTourOwner(booking, currentUser.getId())) {
            return;
        }

        throw new AppException(ErrorCode.UNAUTHORIZED);
    }

    private boolean isHomestayOwner(Booking booking, Long userId) {
        if (!"HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
            return false;
        }

        Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
        return homestay != null
                && homestay.getOwner() != null
                && userId.equals(homestay.getOwner().getId());
    }

    private boolean isTourOwner(Booking booking, Long userId) {
        if (!"TOUR".equalsIgnoreCase(booking.getBookingType()) || booking.getTourId() == null) {
            return false;
        }

        return invoiceRepository.findTourWithImagesById(booking.getTourId())
                .map(tour -> tour.getOwner() != null && userId.equals(tour.getOwner().getId()))
                .orElse(false);
    }

    private boolean isRefundablePaymentStatus(String paymentStatus) {
        return List.of("PAID", "COMPLETED", "PAID_AT_HOMESTAY").contains(paymentStatus);
    }

    private boolean requiresRefundBankInfo(Payment payment) {
        return payment != null
                && payment.getPaymentMethod() != null
                && !"CASH".equalsIgnoreCase(payment.getPaymentMethod());
    }

    private void validateRefundBankInfo(RefundRequest request) {
        if (trimToNull(request.getRefundBankName()) == null
                || trimToNull(request.getRefundAccountNumber()) == null
                || trimToNull(request.getRefundAccountHolder()) == null) {
            throw new AppException(ErrorCode.REFUND_BANK_INFO_REQUIRED);
        }
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String normalizeStatusFilter(String status) {
        if (status == null || status.isBlank()) {
            return status;
        }
        if ("CANCELED".equalsIgnoreCase(status)) {
            return "CANCELLED";
        }
        return status.toUpperCase();
    }

    private List<String> parseConfiguredEmails(String emails) {
        if (emails == null || emails.isBlank()) {
            return List.of();
        }

        return List.of(emails.split(","))
                .stream()
                .map(this::trimToNull)
                .filter(email -> email != null && !email.isBlank())
                .toList();
    }

    private List<String> resolveRefundRequestRecipients(Booking booking) {
        Set<String> recipients = new LinkedHashSet<>(parseConfiguredEmails(refundAdminEmails));

        if ("HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
            Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
            if (homestay != null) {
                String homestayEmail = trimToNull(homestay.getEmail());
                if (homestayEmail != null) {
                    recipients.add(homestayEmail);
                }
                if (homestay.getOwner() != null) {
                    String ownerEmail = trimToNull(homestay.getOwner().getEmail());
                    if (ownerEmail != null) {
                        recipients.add(ownerEmail);
                    }
                }
            }
        } else if ("TOUR".equalsIgnoreCase(booking.getBookingType()) && booking.getTourId() != null) {
            invoiceRepository.findTourWithImagesById(booking.getTourId()).ifPresent(tour -> {
                if (tour.getOwner() != null) {
                    String ownerEmail = trimToNull(tour.getOwner().getEmail());
                    if (ownerEmail != null) {
                        recipients.add(ownerEmail);
                    }
                }
            });
        }

        return new ArrayList<>(recipients);
    }

    private void sendRefundRequestedNotifications(Booking booking, Invoice invoice, Payment payment) {
        List<String> recipients = resolveRefundRequestRecipients(booking);
        if (recipients.isEmpty()) {
            return;
        }

        String subject = "[Smart Travel] Có yêu cầu hoàn tiền mới - " + safeInvoiceNumber(invoice, booking);
        String content = buildRefundRequestedEmailContent(booking, invoice, payment);

        try {
            emailService.sendHtmlEmail(recipients.toArray(String[]::new), subject, content);
        } catch (RuntimeException e) {
            log.error("Không thể gửi email thông báo yêu cầu hoàn tiền cho booking {}", booking.getId(), e);
        }
    }

    private void sendRefundApprovedNotification(Booking booking, Invoice invoice) {
        User customer = booking.getUser();
        String customerEmail = customer != null ? trimToNull(customer.getEmail()) : null;
        if (customerEmail == null) {
            return;
        }

        String subject = "[Smart Travel] Yêu cầu hoàn tiền đã được xác nhận - " + safeInvoiceNumber(invoice, booking);
        String content = buildRefundApprovedEmailContent(booking, invoice, customer);

        try {
            emailService.sendHtmlEmail(new String[]{customerEmail}, subject, content);
        } catch (RuntimeException e) {
            log.error("Không thể gửi email xác nhận hoàn tiền cho booking {}", booking.getId(), e);
        }
    }

    private String buildRefundRequestedEmailContent(Booking booking, Invoice invoice, Payment payment) {
        String customerName = booking.getUser() != null && booking.getUser().getFullName() != null
                ? booking.getUser().getFullName()
                : "Khách hàng";

        return "<html><body>"
                + "<h2>Yêu cầu hoàn tiền mới</h2>"
                + "<p><b>Mã đơn:</b> " + safeInvoiceNumber(invoice, booking) + "</p>"
                + "<p><b>Khách hàng:</b> " + customerName + "</p>"
                + "<p><b>Email khách:</b> " + safeText(booking.getUser() != null ? booking.getUser().getEmail() : null) + "</p>"
                + "<p><b>Loại dịch vụ:</b> " + safeText(booking.getBookingType()) + "</p>"
                + "<p><b>Phương thức thanh toán:</b> " + safeText(payment != null ? payment.getPaymentMethod() : null) + "</p>"
                + "<p><b>Số tiền:</b> " + safeAmount(booking.getFinalPrice()) + " VND</p>"
                + "<p><b>Lý do hủy/hoàn:</b> " + safeText(booking.getCancellationReason()) + "</p>"
                + "<hr/>"
                + "<p><b>Ngân hàng hoàn tiền:</b> " + safeText(invoice != null ? invoice.getRefundBankName() : null) + "</p>"
                + "<p><b>Chi nhánh:</b> " + safeText(invoice != null ? invoice.getRefundBankBranch() : null) + "</p>"
                + "<p><b>Số tài khoản:</b> " + safeText(invoice != null ? invoice.getRefundAccountNumber() : null) + "</p>"
                + "<p><b>Chủ tài khoản:</b> " + safeText(invoice != null ? invoice.getRefundAccountHolder() : null) + "</p>"
                + "<p>Vui lòng vào phần quản lý đơn để kiểm tra và xác nhận hoàn tiền cho khách.</p>"
                + "</body></html>";
    }

    private String buildRefundApprovedEmailContent(Booking booking, Invoice invoice, User customer) {
        String customerName = customer != null && customer.getFullName() != null
                ? customer.getFullName()
                : "Khách hàng";

        return "<html><body>"
                + "<h2>Yêu cầu hoàn tiền đã được xác nhận</h2>"
                + "<p>Xin chào <b>" + customerName + "</b>,</p>"
                + "<p>Yêu cầu hoàn tiền cho đơn <b>" + safeInvoiceNumber(invoice, booking) + "</b> đã được quản lý xác nhận.</p>"
                + "<p><b>Số tiền hoàn:</b> " + safeAmount(booking.getFinalPrice()) + " VND</p>"
                + "<p><b>Tài khoản nhận hoàn:</b> " + safeText(invoice != null ? invoice.getRefundAccountNumber() : null) + "</p>"
                + "<p><b>Ngân hàng:</b> " + safeText(invoice != null ? invoice.getRefundBankName() : null) + "</p>"
                + "<p>Hệ thống sẽ tiến hành hoàn tiền theo quy trình nội bộ trong thời gian sớm nhất.</p>"
                + "<p>Trân trọng,<br/>Smart Travel</p>"
                + "</body></html>";
    }

    private String safeInvoiceNumber(Invoice invoice, Booking booking) {
        if (invoice != null && trimToNull(invoice.getInvoiceNumber()) != null) {
            return invoice.getInvoiceNumber();
        }
        return "BOOKING-" + booking.getId();
    }

    private String safeText(String value) {
        String trimmed = trimToNull(value);
        return trimmed != null ? trimmed : "N/A";
    }

    private String safeAmount(BigDecimal value) {
        return value != null ? value.stripTrailingZeros().toPlainString() : "0";
    }
}
