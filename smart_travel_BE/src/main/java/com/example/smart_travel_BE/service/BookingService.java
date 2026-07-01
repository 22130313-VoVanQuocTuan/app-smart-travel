package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.booking.request.BookingRequest;
import com.example.smart_travel_BE.dto.booking.request.CancelBookingRequest;
import com.example.smart_travel_BE.dto.booking.response.BookingResponse;
import com.example.smart_travel_BE.dto.booking.response.CancellationPolicyResponse;
import com.example.smart_travel_BE.dto.booking.response.HostBookingListResponse;
import com.example.smart_travel_BE.dto.booking.response.UserBookingResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final TourRepository tourRepository;
    private final HomestayRepository homestayRepository;
    private final VoucherRepository voucherRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final UserVoucherRepository userVoucherRepository;
    private final BookingTourRepository bookingTourRepository;
    private final UserRepository userRepository;
    private final SystemConfigRepository systemConfigRepository;
    private final InvoiceRepository invoiceRepository;
    private final UserProfileRepository userProfileRepository;

    @Transactional
    public BookingResponse createBooking(BookingRequest request, User currentUser) {

        // Validate cơ bản
        if (request.getStartDate() == null) {
            throw new AppException(ErrorCode.REQUIRED_FIELD_MISSING);
        }

        if (!"HOMESTAY".equalsIgnoreCase(request.getBookingType())) {
            throw new AppException(ErrorCode.INVALID_BOOKING_TYPE);
        }

        // 1. Kiểm tra Homestay
        Homestay homestay = homestayRepository.findById(request.getHotelId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        if (!homestay.getIsActive()) {
            throw new AppException(ErrorCode.HOMESTAY_NOT_ACTIVE);
        }

        // 2. Kiểm tra Room Type
        if (request.getRoomTypeId() == null) {
            throw new AppException(ErrorCode.ROOM_TYPE_NOT_FOUND);
        }

        RoomType roomType = roomTypeRepository.findById(request.getRoomTypeId())
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_TYPE_NOT_FOUND));

        if (!roomType.getHomestay().getId().equals(homestay.getId())) {
            throw new AppException(ErrorCode.ROOM_TYPE_NOT_BELONG_TO_HOMESTAY);
        }

        if (request.getEndDate() == null) {
            throw new AppException(ErrorCode.REQUIRED_FIELD_MISSING);
        }

        if (request.getNumberOfRooms() == null || request.getNumberOfRooms() <= 0) {
            throw new AppException(ErrorCode.INVALID_NUMBER_OF_ROOMS);
        }

        if (roomType.getAvailableRooms() < request.getNumberOfRooms()) {
            throw new AppException(ErrorCode.ROOM_NOT_AVAILABLE);
        }

        // 3. Tính số đêm
        long nights = java.time.temporal.ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate());
        if (nights <= 0) {
            throw new AppException(ErrorCode.BOOKING_DATE_INVALID);
        }

        // 4. Tính tiền phòng
        BigDecimal hotelTotalPrice = roomType.getPrice()
                .multiply(BigDecimal.valueOf(request.getNumberOfRooms()))
                .multiply(BigDecimal.valueOf(nights));

        // 5. Tạo Booking
        Booking booking = new Booking();
        booking.setUser(currentUser);
        booking.setBookingType("HOMESTAY");
        booking.setHotelId(homestay.getId());
        booking.setTourId(null);
        booking.setStartDate(request.getStartDate());
        booking.setEndDate(request.getEndDate());
        booking.setNumberOfPeople(request.getNumberOfPeople());
        booking.setNumberOfRooms(request.getNumberOfRooms());
        booking.setTotalPrice(hotelTotalPrice);
        booking.setSpecialRequests(request.getSpecialRequests());
        booking.setStatus("PENDING");
        booking.setCreatedAt(LocalDateTime.now());
        booking.setUpdatedAt(LocalDateTime.now());
        booking.setRoomType(roomType);
        booking.setBookingTours(new ArrayList<>());

        // 6. Xử lý Tour đi kèm
        BigDecimal totalTourPrice = BigDecimal.ZERO;

        if (request.getTours() != null && !request.getTours().isEmpty()) {

            for (BookingRequest.TourBookingItem tourItem : request.getTours()) {
                Tour tour = tourRepository.findById(tourItem.getTourId())
                        .orElseThrow(() -> new AppException(ErrorCode.TOUR_NOT_FOUND));

                if (!tour.getIsActive()) {
                    throw new AppException(ErrorCode.TOUR_NOT_ACTIVE);
                }

                if (tourItem.getNumberOfPeople() == null || tourItem.getNumberOfPeople() <= 0) {
                    throw new AppException(ErrorCode.REQUIRED_FIELD_MISSING);
                }

                if (tourItem.getNumberOfPeople() > tour.getMaxPeople()) {
                    throw new AppException(ErrorCode.TOUR_MAX_PEOPLE_EXCEEDED);
                }

                if (tourItem.getNumberOfPeople() < tour.getMinPeople()) {
                    throw new AppException(ErrorCode.TOUR_MIN_PEOPLE_NOT_MET);
                }

                if (tourItem.getTourDate() == null) {
                    throw new AppException(ErrorCode.TOUR_DATE_INVALID);
                }

                if (tourItem.getTourDate().isBefore(request.getStartDate()) ||
                        tourItem.getTourDate().isAfter(request.getEndDate())) {
                    throw new AppException(ErrorCode.TOUR_DATE_OUT_OF_STAY);
                }

                long dayOfTour = java.time.temporal.ChronoUnit.DAYS.between(request.getStartDate(), tourItem.getTourDate()) + 1;

                if (dayOfTour < 1 || dayOfTour > tour.getDurationDays()) {
                    throw new AppException(ErrorCode.TOUR_DATE_INVALID);
                }

                boolean hasScheduleForDay = tour.getSchedules().stream()
                        .anyMatch(schedule -> schedule.getDayNumber() != null &&
                                schedule.getDayNumber().equals((int) dayOfTour));

                if (!hasScheduleForDay) {
                    throw new AppException(ErrorCode.TOUR_NO_SCHEDULE);
                }

                if (tourItem.getNumberOfPeople() > request.getNumberOfPeople()) {
                    throw new AppException(ErrorCode.TOUR_PEOPLE_EXCEED_BOOKING);
                }

                BigDecimal tourPrice = tour.getPricePerPerson()
                        .multiply(BigDecimal.valueOf(tourItem.getNumberOfPeople()));

                BookingTour bookingTour = new BookingTour();
                bookingTour.setBooking(booking);
                bookingTour.setTour(tour);
                bookingTour.setTourDate(tourItem.getTourDate());
                bookingTour.setNumberOfPeople(tourItem.getNumberOfPeople());
                bookingTour.setUnitPrice(tour.getPricePerPerson());
                bookingTour.setTotalPrice(tourPrice);
                bookingTour.setStatus("PENDING");
                bookingTour.setCreatedAt(LocalDateTime.now());

                booking.getBookingTours().add(bookingTour);
                totalTourPrice = totalTourPrice.add(tourPrice);

                tour.setBookingCount(tour.getBookingCount() + 1);
                tourRepository.save(tour);
            }
        }

        // 7. Tính tổng tiền
        BigDecimal totalPrice = hotelTotalPrice.add(totalTourPrice);
        booking.setTotalPrice(totalPrice);

        // 8. Xử lý Voucher
        BigDecimal discountAmount = BigDecimal.ZERO;

        if (request.getCouponCode() != null && !request.getCouponCode().isEmpty()) {
            Voucher voucher = voucherRepository.findByCode(request.getCouponCode())
                    .orElseThrow(() -> new AppException(ErrorCode.VOUCHER_NOT_FOUND));

            if (!voucher.getIsActive()) {
                throw new AppException(ErrorCode.VOUCHER_INACTIVE);
            }

            if (voucher.getUsageLimit() != null && voucher.getUsedCount() >= voucher.getUsageLimit()) {
                throw new AppException(ErrorCode.VOUCHER_USAGE_LIMIT_EXCEEDED);
            }

            if (voucher.getExpiryDate().isBefore(LocalDateTime.now())) {
                throw new AppException(ErrorCode.VOUCHER_EXPIRED);
            }

            if (voucher.getMinOrderValue() != null && totalPrice.compareTo(voucher.getMinOrderValue()) < 0) {
                throw new AppException(ErrorCode.VOUCHER_MIN_ORDER_NOT_MET);
            }

            if (voucher.getPointsRequired() != null && voucher.getPointsRequired() > 0) {
                UserVoucher userVoucher = userVoucherRepository
                        .findValidVoucher(currentUser.getId(), request.getCouponCode())
                        .orElseThrow(() -> new AppException(ErrorCode.VOUCHER_NOT_OWNED));

                if (userVoucher.getIsUsed()) {
                    throw new AppException(ErrorCode.VOUCHER_ALREADY_USED);
                }

                userVoucher.setIsUsed(true);
                userVoucherRepository.save(userVoucher);
            }

            // Tính số tiền giảm
            if ("FIXED".equalsIgnoreCase(voucher.getDiscountType())) {
                discountAmount = voucher.getDiscountAmount();
                if (discountAmount.compareTo(totalPrice) > 0) {
                    discountAmount = totalPrice;
                }
            } else if ("PERCENTAGE".equalsIgnoreCase(voucher.getDiscountType())) {
                BigDecimal percent = voucher.getDiscountAmount().divide(BigDecimal.valueOf(100));
                discountAmount = totalPrice.multiply(percent);
                if (voucher.getMaxDiscount() != null && discountAmount.compareTo(voucher.getMaxDiscount()) > 0) {
                    discountAmount = voucher.getMaxDiscount();
                }
            }

            voucher.setUsedCount(voucher.getUsedCount() + 1);
            voucherRepository.save(voucher);

            booking.setCouponCode(request.getCouponCode());
        }

        booking.setDiscountAmount(discountAmount);

        BigDecimal finalPrice = totalPrice.subtract(discountAmount);
        if (finalPrice.compareTo(BigDecimal.ZERO) < 0) {
            finalPrice = BigDecimal.ZERO;
        }
        booking.setFinalPrice(finalPrice);
        BigDecimal taxRate = getTaxRate();
        BigDecimal taxAmount = getTaxAmount(finalPrice, taxRate);
        booking.setTotalWithTax(calculateTotalWithTax(finalPrice, taxAmount));

        // 9. Lưu booking (không trừ số phòng vì kiểm tra theo từng ngày cụ thể dựa vào lịch booking hiện có)
        Booking savedBooking = bookingRepository.save(booking);

        if (booking.getBookingTours() != null && !booking.getBookingTours().isEmpty()) {
            for (BookingTour bt : booking.getBookingTours()) {
                bt.setBooking(savedBooking);
                bookingTourRepository.save(bt);
            }
        }

        // 10. Tạo response
        List<BookingResponse.TourBookingInfo> tourInfos = new ArrayList<>();
        if (savedBooking.getBookingTours() != null && !savedBooking.getBookingTours().isEmpty()) {
            for (BookingTour bt : savedBooking.getBookingTours()) {
                tourInfos.add(BookingResponse.TourBookingInfo.builder()
                        .tourId(bt.getTour().getId())
                        .tourName(bt.getTour().getName())
                        .tourDate(bt.getTourDate())
                        .numberOfPeople(bt.getNumberOfPeople())
                        .unitPrice(bt.getUnitPrice())
                        .totalPrice(bt.getTotalPrice())
                        .status(bt.getStatus())
                        .build());
            }
        }

        String message = "Đặt homestay thành công";
        if (totalTourPrice.compareTo(BigDecimal.ZERO) > 0) {
            message += " và " + tourInfos.size() + " tour đi kèm";
        }

        return BookingResponse.builder()
                .id(savedBooking.getId())
                .bookingType(savedBooking.getBookingType())
                .hotelId(homestay.getId())
                .hotelName(homestay.getName())
                .roomTypeId(roomType.getId())
                .roomTypeName(roomType.getName())
                .startDate(savedBooking.getStartDate())
                .endDate(savedBooking.getEndDate())
                .nights(nights)
                .numberOfPeople(savedBooking.getNumberOfPeople())
                .numberOfRooms(savedBooking.getNumberOfRooms())
                .tours(tourInfos)
                .hotelPrice(hotelTotalPrice)
                .totalTourPrice(totalTourPrice)
                .totalPrice(totalPrice)
                .discountAmount(discountAmount)
                .couponCode(savedBooking.getCouponCode())
                .finalPrice(savedBooking.getFinalPrice())
                .taxRate(taxRate)
                .taxAmount(taxAmount)
                .totalWithTax(resolveStoredTotalWithTax(savedBooking, taxRate))
                .status(savedBooking.getStatus())
                .message(message)
                .build();
    }

    // ==================== HOST BOOKING MANAGEMENT ====================

    /**
     * Lấy danh sách booking của host
     */
    public List<HostBookingListResponse> getHostBookings(Long userId) {
        // Verify user is a HOST
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        
        // Get all homestays owned by this host
        List<Homestay> homestays = homestayRepository.findByOwnerIdAndIsActiveTrue(userId);
        
        if (homestays.isEmpty()) {
            return new ArrayList<>();
        }
        
        List<Booking> bookings = new ArrayList<>();
        for (Homestay homestay : homestays) {
            bookings.addAll(bookingRepository.findByHotelIdOrderByStartDateDesc(homestay.getId()));
        }
        
        return bookings.stream()
                .map(this::convertToHostBookingListResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy booking detail với full information
     */
    public BookingResponse getHostBookingDetail(Long bookingId, Long userId) {
        Booking booking = invoiceRepository.findFullBookingById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));
        
        // Verify authorization - host must own this homestay
        Homestay homestay = homestayRepository.findById(booking.getHotelId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));
        
        if (!homestay.getOwner().getId().equals(userId)) {
            throw new AppException(ErrorCode.NOT_OWNER);
        }
        
        // Build response
        return buildBookingResponse(booking);
    }
    
    /**
     * Get bookings by date range and status for calendar view
     */
    public List<HostBookingListResponse> getHostBookingsByDateRange(Long userId, LocalDate startDate, LocalDate endDate, String status) {
        // Get all homestays
        List<Homestay> homestays = homestayRepository.findByOwnerIdAndIsActiveTrue(userId);
        
        if (homestays.isEmpty()) {
            return new ArrayList<>();
        }
        
        List<Booking> bookings = new ArrayList<>();
        for (Homestay homestay : homestays) {
            List<Booking> homestayBookings;
            
            if (status != null && !status.isEmpty()) {
                homestayBookings = bookingRepository.findByHotelIdAndStatus(homestay.getId(), status);
            } else {
                homestayBookings = bookingRepository.findByHotelIdAndDateRange(
                    homestay.getId(), startDate, endDate
                );
            }
            
            // Filter by date range
            bookings.addAll(homestayBookings.stream()
                    .filter(b -> !b.getStartDate().isBefore(startDate) && !b.getEndDate().isAfter(endDate))
                    .collect(Collectors.toList()));
        }
        
        return bookings.stream()
                .map(this::convertToHostBookingListResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Update booking status
     */
    @Transactional
    public void updateBookingStatus(Long bookingId, String newStatus, Long userId, String cancellationReason) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));
        
        // Verify authorization
        Homestay homestay = homestayRepository.findById(booking.getHotelId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));
        
        if (!homestay.getOwner().getId().equals(userId)) {
            throw new AppException(ErrorCode.NOT_OWNER);
        }
        
        // Validate status transition
        if (!isValidStatusTransition(booking.getStatus(), newStatus)) {
            throw new AppException(ErrorCode.INVALID_BOOKING_STATUS);
        }
        
        // Update status
        booking.setStatus(newStatus);
        
        // Restore available rooms when CHECKED_OUT or CANCELLED
        if ("CHECKED_OUT".equals(newStatus) || "CANCELLED".equals(newStatus)) {
            if ("CANCELLED".equals(newStatus)) {
                booking.setCancellationReason(cancellationReason);
            }
            
            // Restore available rooms
            if (booking.getRoomType() != null) {
                RoomType roomType = booking.getRoomType();
                roomType.setAvailableRooms(roomType.getAvailableRooms() + booking.getNumberOfRooms());
                roomTypeRepository.save(roomType);
            }
            
            homestay.setAvailableRooms(homestay.getAvailableRooms() + booking.getNumberOfRooms());
            homestayRepository.save(homestay);
        }

        if ("COMPLETED".equals(newStatus)) {
            rewardExperiencePointsIfEligible(booking);
        }
        
        booking.setUpdatedAt(LocalDateTime.now());
        bookingRepository.save(booking);
    }
    
    /**
     * Check if status transition is valid
     */
    private boolean isValidStatusTransition(String currentStatus, String newStatus) {
        // Valid transitions:
        // PENDING -> CONFIRMED, CANCELLED
        // CONFIRMED -> CHECKED_IN, CANCELLED
        // CHECKED_IN -> CHECKED_OUT, CANCELLED
        // CHECKED_OUT -> COMPLETED, CANCELLED
        // COMPLETED -> (no change)
        // CANCELLED -> (no change)
        
        if (currentStatus.equals(newStatus)) {
            return false; // No need to update if same status
        }
        
        if (currentStatus.equals("COMPLETED") || currentStatus.equals("CANCELLED")) {
            return false; // Can't change completed or cancelled bookings
        }
        
        if ("CONFIRMED".equals(newStatus) && "PENDING".equals(currentStatus)) return true;
        if ("CHECKED_IN".equals(newStatus) && "CONFIRMED".equals(currentStatus)) return true;
        if ("CHECKED_OUT".equals(newStatus) && "CHECKED_IN".equals(currentStatus)) return true;
        if ("COMPLETED".equals(newStatus) && "CHECKED_OUT".equals(currentStatus)) return true;
        if ("CANCELLED".equals(newStatus)) return true;
        
        return false;
    }
    
    /**
     * Convert Booking to HostBookingListResponse
     */
    private HostBookingListResponse convertToHostBookingListResponse(Booking booking) {
        BigDecimal taxRate = getTaxRate();
        return HostBookingListResponse.builder()
                .id(booking.getId())
                .bookingType(booking.getBookingType())
                .hotelId(booking.getHotelId())
                .hotelName(booking.getHotelId() != null ? getHomestayName(booking.getHotelId()) : "")
                .guestName(booking.getUser() != null ? booking.getUser().getFullName() : "")
                .guestPhone(booking.getUser() != null ? booking.getUser().getPhone() : "")
                .roomTypeName(booking.getRoomType() != null ? booking.getRoomType().getName() : "")
                .startDate(booking.getStartDate())
                .endDate(booking.getEndDate())
                .numberOfRooms(booking.getNumberOfRooms())
                .numberOfPeople(booking.getNumberOfPeople())
                .totalPrice(booking.getTotalPrice())
                .finalPrice(booking.getFinalPrice())
                .totalWithTax(resolveStoredTotalWithTax(booking, taxRate))
                .status(booking.getStatus())
                .createdAt(booking.getCreatedAt())
                .updatedAt(booking.getUpdatedAt())
                .build();
    }
    
    /**
     * Helper to get homestay name
     */
    private String getHomestayName(Long homestayId) {
        return homestayRepository.findById(homestayId)
                .map(Homestay::getName)
                .orElse("");
    }
    
    /**
     * Build full BookingResponse
     */
    private BookingResponse buildBookingResponse(Booking booking) {
        long nights = java.time.temporal.ChronoUnit.DAYS.between(
            booking.getStartDate(), booking.getEndDate()
        );
        
        RoomType roomType = booking.getRoomType();
        BigDecimal hotelPrice = roomType != null ? 
            roomType.getPrice()
                .multiply(BigDecimal.valueOf(booking.getNumberOfRooms()))
                .multiply(BigDecimal.valueOf(nights)) :
            BigDecimal.ZERO;
        
        List<BookingResponse.TourBookingInfo> tourInfos = new ArrayList<>();
        BigDecimal totalTourPrice = BigDecimal.ZERO;
        
        if (booking.getBookingTours() != null && !booking.getBookingTours().isEmpty()) {
            for (BookingTour bt : booking.getBookingTours()) {
                tourInfos.add(BookingResponse.TourBookingInfo.builder()
                        .tourId(bt.getTour().getId())
                        .tourName(bt.getTour().getName())
                        .tourDate(bt.getTourDate())
                        .numberOfPeople(bt.getNumberOfPeople())
                        .unitPrice(bt.getUnitPrice())
                        .totalPrice(bt.getTotalPrice())
                        .status(bt.getStatus())
                        .build());
                totalTourPrice = totalTourPrice.add(bt.getTotalPrice());
            }
        }
        
        Homestay homestay = homestayRepository.findById(booking.getHotelId()).orElse(null);
        Payment payment = booking.getPayment();
        User customer = booking.getUser();
        BigDecimal taxRate = getTaxRate();
        BigDecimal taxAmount = getTaxAmount(booking, taxRate);
        BigDecimal totalWithTax = resolveStoredTotalWithTax(booking, taxRate);

        return BookingResponse.builder()
                .id(booking.getId())
                .bookingType(booking.getBookingType())
                .hotelId(booking.getHotelId())
                .hotelName(homestay != null ? homestay.getName() : "")
                .roomTypeId(roomType != null ? roomType.getId() : null)
                .roomTypeName(roomType != null ? roomType.getName() : "")
                .startDate(booking.getStartDate())
                .endDate(booking.getEndDate())
                .nights(nights)
                .numberOfPeople(booking.getNumberOfPeople())
                .numberOfRooms(booking.getNumberOfRooms())
                .tours(tourInfos)
                .hotelPrice(hotelPrice)
                .totalTourPrice(totalTourPrice)
                .totalPrice(booking.getTotalPrice())
                .discountAmount(booking.getDiscountAmount())
                .couponCode(booking.getCouponCode())
                .finalPrice(booking.getFinalPrice())
                .taxRate(taxRate)
                .taxAmount(taxAmount)
                .totalWithTax(totalWithTax)
                .status(booking.getStatus())
                .cancellationReason(booking.getCancellationReason())
                .paymentStatus(payment != null ? payment.getStatus() : null)
                .paymentMethod(payment != null ? payment.getPaymentMethod() : null)
                .customerName(customer != null ? customer.getFullName() : "KhÃ¡ch hÃ ng")
                .customerPhone(customer != null ? customer.getPhone() : null)
                .customerEmail(customer != null ? customer.getEmail() : null)
                .build();
    }


    // ==================== USER BOOKING MANAGEMENT ====================

    /**
     * Lấy tất cả booking của user hiện tại
     */
    @Transactional(readOnly = true)
    public List<UserBookingResponse> getUserBookings(User currentUser) {
        List<Booking> bookings = bookingRepository.findUserBookingsWithRoomTypeByUserId(currentUser.getId());
        return convertToUserBookingResponses(bookings);
    }

    /**
     * Lấy booking hiện tại (đang diễn ra hoặc sắp diễn ra)
     */
    @Transactional(readOnly = true)
    public List<UserBookingResponse> getCurrentBookings(User currentUser) {
        LocalDate today = LocalDate.now();

        List<Booking> bookings = bookingRepository.findCurrentBookingsWithRoomType(
                currentUser.getId(),
                today,
                "CANCELLED"
        );

        List<Booking> currentBookings = bookings.stream()
                .filter(b -> !"COMPLETED".equals(b.getStatus()))
                .collect(Collectors.toList());

        return convertToUserBookingResponses(currentBookings);
    }

    /**
     * Lấy lịch sử booking (đã kết thúc)
     */
    @Transactional(readOnly = true)
    public List<UserBookingResponse> getBookingHistory(User currentUser) {
        List<Booking> bookings = bookingRepository.findBookingHistoryWithRoomType(
                currentUser.getId(),
                List.of("COMPLETED", "CANCELLED")
        );

        return convertToUserBookingResponses(bookings);
    }

    /**
     * Lấy chi tiết booking cho user
     */
    @Transactional(readOnly = true)
    public UserBookingResponse getUserBookingDetail(Long bookingId, User currentUser) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        // Verify ownership
        if (!booking.getUser().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        Homestay homestay = booking.getHotelId() != null
                ? homestayRepository.findById(booking.getHotelId()).orElse(null)
                : null;
        return convertToUserBookingResponse(booking, homestay);
    }

    /**
     * Hủy booking bởi user
     */
    @Transactional
    public void cancelUserBooking(Long bookingId, CancelBookingRequest request, User currentUser) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        // Verify ownership
        if (!booking.getUser().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        // Check if can cancel
        if (!canUserCancel(booking)) {
            throw new AppException(ErrorCode.BOOKING_CANNOT_CANCEL);
        }

        // Update booking
        booking.setStatus("CANCELLED");
        booking.setCancellationReason(request.getReason() != null ? request.getReason() : "Khách hàng yêu cầu hủy");
        booking.setUpdatedAt(LocalDateTime.now());

        // Restore available rooms
        if (booking.getRoomType() != null) {
            RoomType roomType = booking.getRoomType();
            roomType.setAvailableRooms(roomType.getAvailableRooms() + booking.getNumberOfRooms());
            roomTypeRepository.save(roomType);
        }

        Homestay homestay = homestayRepository.findById(booking.getHotelId()).orElse(null);
        if (homestay != null) {
            homestay.setAvailableRooms(homestay.getAvailableRooms() + booking.getNumberOfRooms());
            homestayRepository.save(homestay);
        }

        bookingRepository.save(booking);
    }

    /**
     * Tìm booking bằng QR code (booking ID)
     */
    @Transactional(readOnly = true)
    public UserBookingResponse findBookingByQR(String qrData, User currentUser) {
        try {
            Long bookingId = Long.parseLong(qrData);
            Booking booking = bookingRepository.findById(bookingId)
                    .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

            // User can only view their own bookings
            if (!booking.getUser().getId().equals(currentUser.getId())) {
                throw new AppException(ErrorCode.UNAUTHORIZED);
            }

            Homestay homestay = booking.getHotelId() != null
                    ? homestayRepository.findById(booking.getHotelId()).orElse(null)
                    : null;
            return convertToUserBookingResponse(booking, homestay);
        } catch (NumberFormatException e) {
            throw new AppException(ErrorCode.INVALID_QR_CODE);
        }
    }

    /**
     * Check if user can cancel booking
     */
    private boolean canUserCancel(Booking booking) {
        String status = booking.getStatus();

        // Can only cancel PENDING or CONFIRMED bookings
        if (!"PENDING".equals(status) && !"CONFIRMED".equals(status)) {
            return false;
        }

        // Cannot cancel if start date is in the past
        if (booking.getStartDate().isBefore(LocalDate.now())) {
            return false;
        }

        // Lấy cấu hình từ SystemConfig
        SystemConfig config = systemConfigRepository.findFirstConfig()
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        // Lấy số giờ được phép hủy (mặc định 24 nếu null)
        Integer cancelBeforeHours = config.getCancelBeforeHours();
        if (cancelBeforeHours == null) {
            cancelBeforeHours = 24; // Giá trị mặc định
        }

        // Tính thời hạn hủy: Ví dụ check-in lúc 00:00 ngày startDate, trừ đi số giờ cho phép
        LocalDateTime cancellationDeadline = booking.getStartDate()
                .atStartOfDay()
                .minusHours(cancelBeforeHours);

        // Kiểm tra xem có còn trong thời hạn hủy không (không throw exception ở đây, chỉ return false)
        if (LocalDateTime.now().isAfter(cancellationDeadline)) {
            return false;
        }

        return true;
    }

    /**
     * Convert Booking to UserBookingResponse
     */
    private List<UserBookingResponse> convertToUserBookingResponses(List<Booking> bookings) {
        Map<Long, Homestay> homestayMap = buildHomestayMap(bookings);
        BigDecimal taxRate = getTaxRate();
        return bookings.stream()
                .map(booking -> convertToUserBookingResponse(booking, homestayMap.get(booking.getHotelId()), taxRate))
                .collect(Collectors.toList());
    }

    private Map<Long, Homestay> buildHomestayMap(List<Booking> bookings) {
        Set<Long> hotelIds = bookings.stream()
                .map(Booking::getHotelId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());

        return homestayRepository.findAllById(hotelIds).stream()
                .collect(Collectors.toMap(Homestay::getId, homestay -> homestay));
    }

    private UserBookingResponse convertToUserBookingResponse(Booking booking) {
        Homestay homestay = booking.getHotelId() != null
                ? homestayRepository.findById(booking.getHotelId()).orElse(null)
                : null;
        return convertToUserBookingResponse(booking, homestay);
    }

    private UserBookingResponse convertToUserBookingResponse(Booking booking, Homestay homestay) {
        return convertToUserBookingResponse(booking, homestay, getTaxRate());
    }

    private UserBookingResponse convertToUserBookingResponse(Booking booking, Homestay homestay, BigDecimal taxRate) {
        long nights = java.time.temporal.ChronoUnit.DAYS.between(
                booking.getStartDate(), booking.getEndDate()
        );
        Payment payment = booking.getPayment();
        BigDecimal taxAmount = getTaxAmount(booking, taxRate);
        BigDecimal totalWithTax = resolveStoredTotalWithTax(booking, taxRate);

        return UserBookingResponse.builder()
                .id(booking.getId())
                .bookingType(booking.getBookingType())
                .hotelId(booking.getHotelId())
                .hotelName(homestay != null ? homestay.getName() : "")
                .roomTypeName(booking.getRoomType() != null ? booking.getRoomType().getName() : "")
                .startDate(booking.getStartDate())
                .endDate(booking.getEndDate())
                .nights(nights)
                .numberOfPeople(booking.getNumberOfPeople())
                .numberOfRooms(booking.getNumberOfRooms())
                .totalPrice(booking.getTotalPrice())
                .discountAmount(booking.getDiscountAmount())
                .finalPrice(booking.getFinalPrice())
                .taxRate(taxRate)
                .taxAmount(taxAmount)
                .totalWithTax(totalWithTax)
                .status(booking.getStatus())
                .cancellationReason(booking.getCancellationReason())
                .paymentStatus(payment != null ? payment.getStatus() : null)
                .paymentMethod(payment != null ? payment.getPaymentMethod() : null)
                .hotelAddress(homestay != null ? homestay.getAddress() : "")
                .hotelPhone(homestay != null ? homestay.getPhone() : "")
                .qrCode(String.valueOf(booking.getId())) // QR code = booking ID
                .createdAt(booking.getCreatedAt())
                .checkInTime(booking.getCreatedAt())
                .checkOutTime(booking.getUpdatedAt())
                .build();
    }

    private BigDecimal getTaxRate() {
        return systemConfigRepository.findFirstConfig()
                .map(config -> config.getTaxRate() != null ? config.getTaxRate() : BigDecimal.ZERO)
                .orElse(BigDecimal.ZERO);
    }

    private BigDecimal getTaxAmount(Booking booking, BigDecimal taxRate) {
        if (booking.getInvoice() != null && booking.getInvoice().getTaxAmount() != null) {
            return booking.getInvoice().getTaxAmount();
        }

        BigDecimal baseAmount = booking.getFinalPrice() != null ? booking.getFinalPrice() : BigDecimal.ZERO;
        return getTaxAmount(baseAmount, taxRate);
    }

    private BigDecimal getTaxAmount(BigDecimal baseAmount, BigDecimal taxRate) {
        BigDecimal safeBaseAmount = baseAmount != null ? baseAmount : BigDecimal.ZERO;
        BigDecimal safeTaxRate = taxRate != null ? taxRate : BigDecimal.ZERO;
        return safeBaseAmount.multiply(safeTaxRate)
                .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
    }

    private BigDecimal calculateTotalWithTax(BigDecimal finalPrice, BigDecimal taxAmount) {
        BigDecimal safeFinalPrice = finalPrice != null ? finalPrice : BigDecimal.ZERO;
        BigDecimal safeTaxAmount = taxAmount != null ? taxAmount : BigDecimal.ZERO;
        return safeFinalPrice.add(safeTaxAmount);
    }

    private BigDecimal resolveStoredTotalWithTax(Booking booking, BigDecimal taxRate) {
        if (booking.getTotalWithTax() != null) {
            return booking.getTotalWithTax();
        }
        return calculateTotalWithTax(booking.getFinalPrice(), getTaxAmount(booking, taxRate));
    }

    private void rewardExperiencePointsIfEligible(Booking booking) {
        // Kiểm tra payment
        Payment payment = booking.getPayment();
        if (payment == null) {
            return;
        }

        // Kiểm tra trạng thái booking - chỉ cộng điểm khi hoàn thành hoặc đã thanh toán
        String bookingStatus = booking.getStatus();
        if (bookingStatus == null || !List.of("COMPLETED", "PAID", "PAID_AT_HOMESTAY").contains(bookingStatus)) {
            return;
        }

        // Lấy thông tin khách hàng
        User customer = booking.getUser();
        if (customer == null) {
            return;
        }

        // Tính điểm kinh nghiệm dựa trên giá cuối cùng
        // Mỗi 100.000 VND được 100 điểm
        BigDecimal finalPrice = booking.getFinalPrice();
        long expEarned = finalPrice != null
                ? finalPrice.divide(new BigDecimal("100000"), java.math.RoundingMode.FLOOR).longValue() * 100
                : 0;

        if (expEarned <= 0) {
            return;
        }

        // Lấy hoặc tạo mới UserProfile
        UserProfile profile = userProfileRepository.findByUser(customer).orElseGet(() -> {
            UserProfile newProfile = UserProfile.builder()
                    .user(customer)
                    .experiencePoints(0L)
                    .darkModeEnabled(false)
                    .updatedAt(LocalDateTime.now())
                    .build();
            return userProfileRepository.save(newProfile);
        });

        // Cộng điểm kinh nghiệm
        Long currentPoints = profile.getExperiencePoints() != null ? profile.getExperiencePoints() : 0L;
        profile.setExperiencePoints(currentPoints + expEarned);
        profile.setUpdatedAt(LocalDateTime.now());
        userProfileRepository.save(profile);
    }
    /**
     * Lấy thông tin chính sách hủy cho booking
     */
    public CancellationPolicyResponse getCancellationPolicy(Long bookingId, User currentUser) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new AppException(ErrorCode.BOOKING_NOT_FOUND));

        // Verify ownership
        if (!booking.getUser().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        // Lấy cấu hình hệ thống
        SystemConfig config = systemConfigRepository.findFirstConfig()
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        Integer cancelBeforeHours = config.getCancelBeforeHours() != null ? config.getCancelBeforeHours() : 24;
        BigDecimal cancellationFeePercent = config.getCancellationFeePercent() != null ? config.getCancellationFeePercent() : BigDecimal.ZERO;

        // Kiểm tra xem có thể hủy không
        boolean canCancel = canUserCancel(booking);

        // Tính thời hạn hủy
        LocalDateTime cancellationDeadline = booking.getStartDate()
                .atStartOfDay()
                .minusHours(cancelBeforeHours);

        String cancelDeadlineText = cancellationDeadline.format(
                java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
        );

        // Tính phí hủy ước tính
        BigDecimal estimatedFee = BigDecimal.ZERO;
        String message;

        if (!canCancel) {
            message = "Không thể hủy booking này. ";

            // Kiểm tra lý do không thể hủy
            if (!"PENDING".equals(booking.getStatus()) && !"CONFIRMED".equals(booking.getStatus())) {
                message += "Booking đã ở trạng thái không thể hủy (" + booking.getStatus() + ").";
            } else if (booking.getStartDate().isBefore(LocalDate.now())) {
                message += "Ngày nhận phòng đã qua.";
            } else if (LocalDateTime.now().isAfter(cancellationDeadline)) {
                message += "Đã quá thời hạn hủy (" + cancelBeforeHours + " giờ trước khi nhận phòng).";
            } else {
                message += "Booking không đủ điều kiện hủy.";
            }
        } else {
            // Tính phí hủy
            if (cancellationFeePercent.compareTo(BigDecimal.ZERO) > 0) {
                estimatedFee = booking.getFinalPrice()
                        .multiply(cancellationFeePercent)
                        .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
                message = String.format(
                        "Bạn có thể hủy booking. Phí hủy là %.0f%% (khoảng %,.0f₫). Hãy hủy trước %s để tránh mất phí.",
                        cancellationFeePercent, estimatedFee, cancelDeadlineText
                );
            } else {
                message = String.format(
                        "Bạn có thể hủy booking miễn phí. Hãy hủy trước %s.",
                        cancelDeadlineText
                );
            }
        }

        return CancellationPolicyResponse.builder()
                .canCancel(canCancel)
                .cancelBeforeHours(cancelBeforeHours)
                .cancelDeadline(cancelDeadlineText)
                .cancellationFeePercent(cancellationFeePercent)
                .estimatedCancellationFee(estimatedFee)
                .message(message)
                .build();
    }
}
