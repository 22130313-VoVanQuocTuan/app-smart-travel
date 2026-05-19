package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.invoice.request.CancelOrderRequest;
import com.example.smart_travel_BE.dto.invoice.request.CheckInRequest;
import com.example.smart_travel_BE.dto.invoice.request.CheckOutRequest;
import com.example.smart_travel_BE.dto.invoice.request.RefundApprovalRequest;
import com.example.smart_travel_BE.dto.invoice.response.ActiveInvoiceResponse;
import com.example.smart_travel_BE.dto.invoice.response.AdminInvoiceDetailResponse;
import com.example.smart_travel_BE.dto.invoice.response.AdminInvoiceResponse;
import com.example.smart_travel_BE.dto.invoice.response.InvoiceDetailResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.mapper.InvoiceDetailMapper;
import com.example.smart_travel_BE.mapper.InvoiceMapper;
import com.example.smart_travel_BE.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final BookingRepository bookingRepository;
    private final HomestayRepository hotelRepository;
    private final TourRepository tourRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final InvoiceMapper invoiceMapper;
    private final InvoiceDetailMapper invoiceDetailMapper;
    private final UserProfileRepository userProfileRepository;
    private final SystemConfigRepository systemConfigRepository;

    // ==================== USER INVOICE METHODS ====================

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

    // ==================== REFUND METHODS ====================

    @Transactional
    public void requestRefund(Long bookingId, String reason) {
        User curUser = getCurrentUser();
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        if (!booking.getUser().getId().equals(curUser.getId())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }
        if (!List.of("ACTIVE").contains(booking.getStatus())) {
            throw new AppException(ErrorCode.REFUND_NOT_ALLOWED);
        }
        if ("PENDING_REFUND".equals(booking.getStatus())) {
            throw new AppException(ErrorCode.REFUND_ALREADY_REQUESTED);
        }

        booking.setStatus("PENDING_REFUND");
        booking.setCancellationReason(reason);
        bookingRepository.save(booking);
    }

    public List<ActiveInvoiceResponse> getTransactionHistory(String typeFilter, String statusFilter) {
        User curUser = getCurrentUser();
        List<Booking> bookings = invoiceRepository.findTransactionHistory(
                curUser.getId(),
                typeFilter != null && !typeFilter.isEmpty() ? typeFilter.toUpperCase() : null,
                statusFilter != null && !statusFilter.isEmpty() ? statusFilter : null
        );
        return bookings.stream().map(invoiceMapper::toActiveResponse).toList();
    }

    // ==================== ADMIN INVOICE METHODS ====================

    public List<AdminInvoiceResponse> getAdminInvoices(String invoiceNumber, String status) {
        User currentUser = getCurrentUser();
        String role = currentUser.getRole();

        List<Booking> bookings = invoiceRepository.findAdminInvoices(
                currentUser.getId(),
                role,
                invoiceNumber,
                status
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
        String role = currentUser.getRole();

        Booking booking = invoiceRepository.findFullBookingById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        Invoice invoice = booking.getInvoice();
        Payment payment = booking.getPayment();

        // Kiểm tra quyền
        if (!role.equals("ADMIN")) {
            if (role.equals("HOST") && "HOMESTAY".equalsIgnoreCase(booking.getBookingType())) {
                Homestay homestay = invoiceRepository.findHotelWithImagesById(booking.getHotelId()).orElse(null);
                if (homestay == null || !currentUser.getId().equals(homestay.getOwner().getId())) {
                    throw new AppException(ErrorCode.UNAUTHORIZED);
                }
            } else {
                throw new AppException(ErrorCode.UNAUTHORIZED);
            }
        }

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
                .taxAmount(invoice != null ? invoice.getTaxAmount() : BigDecimal.ZERO)
                .customerName(customer != null ? customer.getFullName() : "Khách lẻ")
                .customerPhone(customer != null ? customer.getPhone() : null)
                .customerEmail(customer != null ? customer.getEmail() : null)
                .build();
    }

    // ==================== CHECK-IN / CHECK-OUT / CANCEL ====================

    @Transactional
    public void checkIn(CheckInRequest request) {
        User currentUser = getCurrentUser();
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        if (!"ACTIVE".equals(booking.getStatus())) {
            throw new AppException(ErrorCode.INVALID_STATUS);
        }

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

        // Chuyển trạng thái sang COMPLETED
        booking.setStatus("COMPLETED");
        booking = bookingRepository.save(booking);

        // THÊM: Cập nhật hoa hồng khi checkout thành công
        updateCommissionAfterCheckout(booking);

        // Tính EXP cho khách hàng
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

    /**
     * Cập nhật hoa hồng khi checkout thành công
     */
    private void updateCommissionAfterCheckout(Booking booking) {
        try {
            Invoice invoice = booking.getInvoice();
            if (invoice == null) {
                log.warn("Không tìm thấy invoice cho booking: {}", booking.getId());
                return;
            }

            // Lấy cấu hình hệ thống
            SystemConfig config = systemConfigRepository.findFirstConfig()
                    .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

            BigDecimal totalAmount = booking.getFinalPrice();
            BigDecimal commissionRate = config.getCommissionRate() != null ? config.getCommissionRate() : BigDecimal.ZERO;
            BigDecimal taxRate = config.getTaxRate() != null ? config.getTaxRate() : BigDecimal.ZERO;

            // Tính lại hoa hồng (nếu cần)
            BigDecimal commissionAmount = totalAmount
                    .multiply(commissionRate)
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            BigDecimal homestayAmount = totalAmount.subtract(commissionAmount);

            // Tính thuế (nếu invoice chưa có)
            if (invoice.getTaxAmount() == null || invoice.getTaxAmount().compareTo(BigDecimal.ZERO) == 0) {
                BigDecimal taxAmount = totalAmount
                        .multiply(taxRate)
                        .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                invoice.setTaxAmount(taxAmount);
            }

            // Cập nhật invoice
            invoice.setCommissionPercentage(commissionRate);
            invoice.setCommissionAmount(commissionAmount);
            invoice.setHomestayAmount(homestayAmount);
            invoice.setCommissionStatus(CommissionStatus.PAID); // Đã thanh toán hoa hồng cho admin
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

        if (!"ACTIVE".equals(booking.getStatus())) {
            throw new AppException(ErrorCode.INVALID_STATUS);
        }

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

        validateOwnerPermission(booking, currentUser);

        booking.setStatus("REFUNDED");
        bookingRepository.save(booking);
    }

    // ==================== HELPER METHODS ====================

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
    }
}