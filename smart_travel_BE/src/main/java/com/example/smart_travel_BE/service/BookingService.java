package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.booking.request.BookingRequest;
import com.example.smart_travel_BE.dto.booking.response.BookingResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
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
    private final BookingTourRepository bookingTourRepository; // Thêm mới

    @Transactional
    public BookingResponse createBooking(BookingRequest request, User currentUser) {

        // Validate cơ bản
        if (request.getStartDate() == null) {
            throw new AppException(ErrorCode.REQUIRED_FIELD_MISSING);
        }

        if (!"HOTEL".equalsIgnoreCase(request.getBookingType())) {
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
        booking.setBookingType("HOTEL");
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

        // 9. Cập nhật số phòng
        roomType.setAvailableRooms(roomType.getAvailableRooms() - request.getNumberOfRooms());
        roomTypeRepository.save(roomType);

        homestay.setAvailableRooms(homestay.getAvailableRooms() - request.getNumberOfRooms());
        homestayRepository.save(homestay);

        // 10. Lưu booking
        Booking savedBooking = bookingRepository.save(booking);

        if (booking.getBookingTours() != null && !booking.getBookingTours().isEmpty()) {
            for (BookingTour bt : booking.getBookingTours()) {
                bt.setBooking(savedBooking);
                bookingTourRepository.save(bt);
            }
        }

        // 11. Tạo response
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
                .status(savedBooking.getStatus())
                .message(message)
                .build();
    }
}