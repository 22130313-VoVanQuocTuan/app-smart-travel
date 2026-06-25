package com.example.smart_travel_BE.service;


import com.example.smart_travel_BE.dto.homestay.request.HomestayCreateRequest;
import com.example.smart_travel_BE.dto.homestay.request.HomestayFilterRequest;
import com.example.smart_travel_BE.dto.homestay.request.RoomTypeCreateRequest;
import com.example.smart_travel_BE.dto.homestay.response.HomestayDetailResponse;
import com.example.smart_travel_BE.dto.homestay.response.HomestayResponse;
import com.example.smart_travel_BE.dto.homestay.response.RoomTypeResponse;
import com.example.smart_travel_BE.dto.homestay.response.TourBriefResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.mapper.HomestayMapper;
import com.example.smart_travel_BE.mapper.RoomTypeMapper;
import com.example.smart_travel_BE.repository.*;
import com.example.smart_travel_BE.specification.HomestaySpecification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class HomestayService {

    @Autowired
    private HomestayRepository hotelRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private TourRepository tourRepository; // THÊM MỚI

    ObjectMapper mapper = new ObjectMapper();
    @Autowired
    private RoomTypeRepository roomTypeRepository;
    @Autowired
    private DestinationRepository destinationRepository;

    @Autowired
    private CloudinaryService cloudinaryService;

    @Autowired
    private InvoiceRepository invoiceRepository;

    //Lấy danh sách khách sạn có phân trang + filter
    public Page<HomestayResponse> getHomestay(HomestayFilterRequest filter) {
        int page = (filter.getPage() != null && filter.getPage() >= 0) ? filter.getPage() : 0;
        int size = (filter.getSize() != null && filter.getSize() > 0) ? filter.getSize() : 10;

        Sort.Direction direction = "desc".equalsIgnoreCase(filter.getSortDir()) ? Sort.Direction.DESC : Sort.Direction.ASC;

        Sort sort = Sort.by(direction, filter.getSortBy());
        Pageable pageable = PageRequest.of(page, size, sort);



        Specification<Homestay> spec = HomestaySpecification.filter(filter);

        Specification<Homestay> activeSpec = (root, query, cb) -> cb.equal(root.get("isActive"), true);
        spec = (spec == null) ? activeSpec : spec.and(activeSpec);

        Page<Homestay> hotelPage = hotelRepository.findAll(spec, pageable);

        return hotelPage.map(hotel -> HomestayResponse.builder()
                .id(hotel.getId())
                .name(hotel.getName())
                .address(hotel.getAddress())
                .pricePerNight(hotel.getMinPrice())
                .stars(hotel.getStarRating())
                .rating(hotel.getAverageRating() != null ? hotel.getAverageRating().doubleValue() : null)
                .numOfReviews(hotel.getReviewCount())
                .thumbnail(hotel.getThumbnail())
                .destinationId(hotel.getDestination() != null ? hotel.getDestination().getId() : null)
                .destinationName(hotel.getDestination() != null ? hotel.getDestination().getName() : null)
                .phone(hotel.getPhone())
                .email(hotel.getEmail())
                .description(hotel.getDescription())
                .amenities(convertAmenitiesToList(hotel.getAmenities()))
                .totalRooms(hotel.getTotalRooms())
                .availableRooms(hotel.getAvailableRooms())
                .latitude(hotel.getLatitude())
                .longitude(hotel.getLongitude())
                .build());
    }

    // Lấy chi tiết khách sạn kèm danh sách phòng khả dụng VÀ TOUR
    @Transactional(readOnly = true)
    public HomestayDetailResponse getHomestayDetail(Long hotelId, LocalDate checkIn, LocalDate checkOut) {
        return getHomestayDetail(hotelId, checkIn, checkOut, false);
    }

    @Transactional(readOnly = true)
    public HomestayDetailResponse getHomestayDetail(Long hotelId, LocalDate checkIn, LocalDate checkOut, boolean forEdit) {
        Homestay homestay = hotelRepository.findById(hotelId)
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        if (Boolean.FALSE.equals(homestay.getIsActive())) {
            throw new AppException(ErrorCode.HOMESTAY_NOT_ACTIVE);
        }

        List<RoomTypeResponse> roomResponses;
        if (forEdit) {
            // Form chỉnh sửa cần toàn bộ loại phòng đã cấu hình
            roomResponses = homestay.getRoomTypes().stream()
                    .map(RoomTypeMapper::toResponse)
                    .collect(Collectors.toList());
        } else {
            // Luồng booking chỉ lấy loại phòng còn trống theo khoảng ngày
            List<Object[]> results = roomTypeRepository.findAvailableRoomsWithCount(hotelId, checkIn, checkOut);

            roomResponses = results.stream().map(obj -> {
                RoomType rt = (RoomType) obj[0];
                int available = ((Number) obj[1]).intValue();
                return RoomTypeResponse.builder()
                        .id(rt.getId())
                        .name(rt.getName())
                        .capacity(rt.getCapacity())
                        .price(rt.getPrice())
                        .totalRooms(rt.getTotalRooms())
                        .availableRooms(available)
                        .amenities(convertAmenitiesToList(rt.getAmenities()))
                        .build();
            }).collect(Collectors.toList());
        }

        // THÊM MỚI: Lấy danh sách tour có thể đặt kèm
        List<TourBriefResponse> availableTours = getAvailableToursForHomestay(homestay, checkIn, checkOut);

        return HomestayDetailResponse.builder()
                .id(homestay.getId())
                .name(homestay.getName())
                .address(homestay.getAddress())
                .description(homestay.getDescription())
                .stars(homestay.getStarRating())
                .rating(homestay.getAverageRating() != null ? homestay.getAverageRating().doubleValue() : null)
                .numOfReviews(homestay.getReviewCount())
                .thumbnail(homestay.getThumbnail())
                .images(homestay.getImages() != null ?
                        homestay.getImages().stream().map(HomestayImage::getImageUrl).collect(Collectors.toList()) : null)
                .destinationName(homestay.getDestination() != null ? homestay.getDestination().getName() : null)
                .provinceName(homestay.getDestination() != null && homestay.getDestination().getProvince() != null ?
                        homestay.getDestination().getProvince().getName() : null)
                .latitude(homestay.getLatitude())
                .longitude(homestay.getLongitude())
                .pricePerNight(homestay.getPricePerNight())
                .rooms(roomResponses)
                .phone(homestay.getPhone())
                .email(homestay.getEmail())
                .amenities(convertAmenitiesToList(homestay.getAmenities()))
                .destinationId(homestay.getDestination() != null ? homestay.getDestination().getId() : null)
                .availableTours(availableTours) // THÊM MỚI
                .ownerId(homestay.getOwner().getId())
                .ownerName(homestay.getOwner().getFullName())
                .build();
    }

    // Lấy danh sách tour có thể đặt kèm homestay
    private List<TourBriefResponse> getAvailableToursForHomestay(
            Homestay homestay,
            LocalDate checkIn,
            LocalDate checkOut) {

        List<Tour> tours;

        if (homestay != null) {
            tours = tourRepository.findActiveToursByHomestay(homestay.getId());
        } else {
            tours = tourRepository.findByIsActiveTrue();
        }

        return tours.stream()
                .filter(tour -> isTourAvailable(tour, checkIn, checkOut))
                .map(this::convertToTourBriefResponse)
                .collect(Collectors.toList());
    }

    // Kiểm tra tour có khả dụng không
    private boolean isTourAvailable(Tour tour, LocalDate checkIn, LocalDate checkOut) {
        if (!tour.getIsActive()) {
            return false;
        }

        // Kiểm tra tour có schedule không
        if (tour.getSchedules() == null || tour.getSchedules().isEmpty()) {
            return false;
        }

        // Kiểm tra tour có đủ số ngày schedule không (từ dayNumber 1 đến durationDays)
        long totalDays = tour.getDurationDays();
        long scheduleDays = tour.getSchedules().stream()
                .map(TourSchedule::getDayNumber)
                .filter(day -> day != null && day >= 1 && day <= totalDays)
                .count();

        // Nếu có ít nhất 1 schedule thì tour khả dụng
        return scheduleDays > 0;
    }

    // Convert Tour -> TourBriefResponse
    private TourBriefResponse convertToTourBriefResponse(Tour tour) {
        // Lấy thumbnail từ images
        String thumbnail = null;
        List<String> imageUrls = new ArrayList<>();

        if (tour.getImages() != null && !tour.getImages().isEmpty()) {
            thumbnail = tour.getImages().stream()
                    .filter(TourImage::getIsPrimary)
                    .findFirst()
                    .map(TourImage::getImageUrl)
                    .orElse(tour.getImages().get(0).getImageUrl());

            imageUrls = tour.getImages().stream()
                    .map(TourImage::getImageUrl)
                    .collect(Collectors.toList());
        }

        // Convert JSON included/excluded
        List<String> includedList = convertAmenitiesToList(tour.getIncluded());
        List<String> excludedList = convertAmenitiesToList(tour.getExcluded());

        return TourBriefResponse.builder()
                .id(tour.getId())
                .name(tour.getName())
                .description(tour.getDescription())
                .durationDays(tour.getDurationDays())
                .durationNights(tour.getDurationNights())
                .pricePerPerson(tour.getPricePerPerson())
                .maxPeople(tour.getMaxPeople())
                .minPeople(tour.getMinPeople())
                .averageRating(tour.getAverageRating() != null ? tour.getAverageRating().doubleValue() : null)
                .reviewCount(tour.getReviewCount())
                .thumbnail(thumbnail)
                .images(imageUrls)
                .included(includedList)
                .excluded(excludedList)
                .build();
    }

    @Transactional
    public HomestayDetailResponse createHomestay(HomestayCreateRequest req) throws JsonProcessingException, IOException {
        String currentUserEmail = getCurrentUserEmail();
        User owner = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (req.getRoomTypes() == null || req.getRoomTypes().isEmpty()) {
            throw new AppException(ErrorCode.ROOM_TYPE_REQUIRED);
        }

        Destination destination = destinationRepository.findById(req.getDestinationId())
                .orElseThrow(() -> new AppException(ErrorCode.DESTINATION_NOT_FOUND));

        Homestay homestay = new Homestay();
        homestay.setOwner(owner);
        homestay.setName(req.getName());
        homestay.setAddress(req.getAddress());
        homestay.setDescription(req.getDescription());
        homestay.setLatitude(req.getLatitude());
        homestay.setLongitude(req.getLongitude());
        homestay.setStarRating(req.getStars());
        homestay.setDestination(destination);
        homestay.setPhone(req.getPhone());
        homestay.setEmail(req.getEmail());
        homestay.setAmenities(mapper.writeValueAsString(
                req.getAmenities() != null ? req.getAmenities() : Collections.emptyList()
        ));
        homestay.setIsActive(true);
        homestay.setImages(new ArrayList<>());
        homestay.setRoomTypes(new ArrayList<>());

        int order = 0;

        // Upload thumbnail
        if (req.getThumbnail() != null && !req.getThumbnail().isEmpty()) {
            String thumbnailUrl = cloudinaryService.uploadFile(req.getThumbnail(), "homestays/thumbnails");
            HomestayImage thumb = new HomestayImage();
            thumb.setHomestay(homestay);
            thumb.setImageUrl(thumbnailUrl);
            thumb.setIsPrimary(true);
            thumb.setDisplayOrder(order++);
            homestay.getImages().add(thumb);
        }

        // Upload gallery images
        if (req.getImages() != null && !req.getImages().isEmpty()) {
            for (MultipartFile file : req.getImages()) {
                if (file == null || file.isEmpty()) continue;
                String imageUrl = cloudinaryService.uploadFile(file, "homestays/galleries");
                HomestayImage img = new HomestayImage();
                img.setHomestay(homestay);
                img.setImageUrl(imageUrl);
                img.setIsPrimary(false);
                img.setDisplayOrder(order++);
                homestay.getImages().add(img);
            }
        }

        // Tính toán từ RoomTypes
        BigDecimal minPrice = null;
        int totalRoomsCounter = 0;

        for (RoomTypeCreateRequest rtReq : req.getRoomTypes()) {
            RoomType rt = new RoomType();
            rt.setHomestay(homestay);
            rt.setName(rtReq.getName());
            rt.setCapacity(rtReq.getCapacity());
            rt.setPrice(rtReq.getPrice());
            rt.setTotalRooms(rtReq.getTotalRooms());
            rt.setAvailableRooms(rtReq.getTotalRooms());
            rt.setAmenities(mapper.writeValueAsString(
                    rtReq.getAmenities() != null ? rtReq.getAmenities() : Collections.emptyList()
            ));

            homestay.getRoomTypes().add(rt);
            totalRoomsCounter += rtReq.getTotalRooms();

            if (minPrice == null || rtReq.getPrice().compareTo(minPrice) < 0) {
                minPrice = rtReq.getPrice();
            }
        }

        homestay.setTotalRooms(totalRoomsCounter);
        homestay.setAvailableRooms(totalRoomsCounter);
        homestay.setPricePerNight(minPrice);

        hotelRepository.save(homestay);
        return HomestayMapper.toDetailResponse(homestay);
    }

    @Transactional
    public HomestayDetailResponse updateHomestay(Long hotelId, HomestayCreateRequest req) throws JsonProcessingException, IOException {
        Homestay homestay = hotelRepository.findById(hotelId)
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));
        validateOwnership(homestay);

        Destination destination = destinationRepository.findById(req.getDestinationId())
                .orElseThrow(() -> new AppException(ErrorCode.DESTINATION_NOT_FOUND));

        homestay.setName(req.getName());
        homestay.setAddress(req.getAddress());
        homestay.setDescription(req.getDescription());
        homestay.setLatitude(req.getLatitude());
        homestay.setLongitude(req.getLongitude());
        homestay.setStarRating(req.getStars());
        homestay.setDestination(destination);
        homestay.setPhone(req.getPhone());
        homestay.setEmail(req.getEmail());
        homestay.setAmenities(mapper.writeValueAsString(
                req.getAmenities() != null ? req.getAmenities() : Collections.emptyList()
        ));

        // Nếu có thumbnail mới, xóa ảnh cũ trên Cloudinary và upload ảnh mới
        if (req.getThumbnail() != null && !req.getThumbnail().isEmpty()) {
            // Xóa ảnh thumbnail cũ trên Cloudinary
            homestay.getImages().stream()
                    .filter(HomestayImage::getIsPrimary)
                    .findFirst()
                    .ifPresent(oldThumb -> {
                        cloudinaryService.deleteFile(oldThumb.getImageUrl());
                        homestay.getImages().remove(oldThumb);
                    });

            // Upload ảnh mới
            String thumbnailUrl = cloudinaryService.uploadFile(req.getThumbnail(), "homestays/thumbnails");
            HomestayImage thumb = new HomestayImage();
            thumb.setHomestay(homestay);
            thumb.setImageUrl(thumbnailUrl);
            thumb.setIsPrimary(true);
            thumb.setDisplayOrder(0);
            homestay.getImages().add(thumb);
        }

        // Đồng bộ gallery ảnh cũ theo danh sách FE giữ lại
        if (Boolean.TRUE.equals(req.getSyncGalleryImages())) {
            Set<String> keepUrls = req.getKeepImageUrls() != null
                    ? new HashSet<>(req.getKeepImageUrls())
                    : Collections.emptySet();

            Iterator<HomestayImage> iterator = homestay.getImages().iterator();
            while (iterator.hasNext()) {
                HomestayImage image = iterator.next();
                if (Boolean.TRUE.equals(image.getIsPrimary())) {
                    continue;
                }
                if (!keepUrls.contains(image.getImageUrl())) {
                    cloudinaryService.deleteFile(image.getImageUrl());
                    iterator.remove();
                }
            }
        }

        // Upload gallery images mới
        if (req.getImages() != null && !req.getImages().isEmpty()) {
            int currentOrder = homestay.getImages().size();
            for (MultipartFile file : req.getImages()) {
                if (file == null || file.isEmpty()) continue;
                String imageUrl = cloudinaryService.uploadFile(file, "homestays/galleries");
                HomestayImage img = new HomestayImage();
                img.setHomestay(homestay);
                img.setImageUrl(imageUrl);
                img.setIsPrimary(false);
                img.setDisplayOrder(currentOrder++);
                homestay.getImages().add(img);
            }
        }

        // Xử lý room types
        homestay.getRoomTypes().clear();
        BigDecimal minPrice = null;
        int totalRoomsCounter = 0;

        if (req.getRoomTypes() != null) {
            for (RoomTypeCreateRequest rtReq : req.getRoomTypes()) {
                RoomType rt = new RoomType();
                rt.setHomestay(homestay);
                rt.setName(rtReq.getName());
                rt.setCapacity(rtReq.getCapacity());
                rt.setPrice(rtReq.getPrice());
                rt.setTotalRooms(rtReq.getTotalRooms());
                rt.setAvailableRooms(rtReq.getTotalRooms());
                rt.setAmenities(mapper.writeValueAsString(
                        rtReq.getAmenities() != null ? rtReq.getAmenities() : Collections.emptyList()
                ));
                homestay.getRoomTypes().add(rt);

                totalRoomsCounter += rtReq.getTotalRooms();

                if (minPrice == null || rtReq.getPrice().compareTo(minPrice) < 0) {
                    minPrice = rtReq.getPrice();
                }
            }
        }

        homestay.setPricePerNight(minPrice);
        homestay.setTotalRooms(totalRoomsCounter);
        homestay.setAvailableRooms(totalRoomsCounter);

        hotelRepository.save(homestay);
        return HomestayMapper.toDetailResponse(homestay);
    }


    @Transactional
    public void deleteHomestay(Long hotelId) {
        Homestay homestay = hotelRepository.findById(hotelId)
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));
        validateOwnership(homestay);

        if (Boolean.FALSE.equals(homestay.getIsActive())) {
            throw new AppException(ErrorCode.HOMESTAY_ALREADY_DELETED);
        }

        homestay.setIsActive(false);
        hotelRepository.save(homestay);
    }

    // Hàm hỗ trợ convert JSON
    private List<String> convertAmenitiesToList(String jsonAmenities) {
        if (jsonAmenities == null || jsonAmenities.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return mapper.readValue(jsonAmenities, new TypeReference<List<String>>() {});
        } catch (JsonProcessingException e) {
            return Collections.singletonList(jsonAmenities);
        }
    }

    private String getCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof User) {
            return ((User) principal).getEmail();
        }
        return authentication.getName();
    }

    private void validateOwnership(Homestay homestay) {
        String currentPrincipal = getCurrentUserEmail();
        boolean isOwner = homestay.getOwner().getEmail().equalsIgnoreCase(currentPrincipal);

        if (!isOwner) {
            throw new AppException(ErrorCode.NOT_OWNER);
        }
    }


    public List<HomestayResponse> getHomestaysByCurrentOwner() {
        String currentUserEmail = getCurrentUserEmail();
        User owner = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        List<Homestay> homestays = hotelRepository.findByOwnerIdAndIsActiveTrue(owner.getId());
        return homestays.stream()
                .map(this::convertToHomestayResponse)
                .collect(Collectors.toList());
    }

    public List<HomestayResponse> getFeaturedHomestays(Integer limit) {
        Pageable pageable = PageRequest.of(0, limit);
        Page<Homestay> homestays = hotelRepository.findTopByOrderByAverageRatingDesc(pageable);
        return homestays.stream()
                .map(this::convertToHomestayResponse)
                .collect(Collectors.toList());
    }

    public List<HomestayResponse> getHomestaysByDestination(Long destinationId) {
        List<Homestay> homestays = hotelRepository.findByDestinationIdAndIsActiveTrue(destinationId);
        return homestays.stream()
                .map(this::convertToHomestayResponse)
                .collect(Collectors.toList());
    }

    public List<HomestayResponse> getHomestaysByPriceRange(BigDecimal minPrice, BigDecimal maxPrice) {
        List<Homestay> homestays = hotelRepository.findByPricePerNightBetweenAndIsActiveTrue(minPrice, maxPrice);
        return homestays.stream()
                .map(this::convertToHomestayResponse)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getAvailableRooms(Long homestayId, LocalDate checkIn, LocalDate checkOut) {
        Homestay homestay = hotelRepository.findById(homestayId)
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        List<Object[]> results = roomTypeRepository.findAvailableRoomsWithCount(homestayId, checkIn, checkOut);

        List<Map<String, Object>> rooms = results.stream().map(obj -> {
            RoomType rt = (RoomType) obj[0];
            int available = ((Number) obj[1]).intValue();

            Map<String, Object> roomMap = new HashMap<>();
            roomMap.put("id", rt.getId());
            roomMap.put("name", rt.getName());
            roomMap.put("capacity", rt.getCapacity());
            roomMap.put("price", rt.getPrice());
            roomMap.put("availableRooms", available);
            roomMap.put("amenities", convertAmenitiesToList(rt.getAmenities()));
            return roomMap;
        }).collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("homestayId", homestayId);
        response.put("homestayName", homestay.getName());
        response.put("checkIn", checkIn);
        response.put("checkOut", checkOut);
        response.put("rooms", rooms);

        return response;
    }

    public List<?> getAvailableToursForHomestay(Long homestayId, LocalDate checkIn, LocalDate checkOut) {
        Homestay homestay = hotelRepository.findById(homestayId)
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));
        return getAvailableToursForHomestay(homestay, checkIn, checkOut);
    }

    public boolean checkAvailability(Long homestayId, Long roomTypeId, LocalDate checkIn, LocalDate checkOut, Integer numberOfRooms) {
        List<Object[]> results = roomTypeRepository.findAvailableRoomsWithCount(homestayId, checkIn, checkOut);

        return results.stream()
                .filter(obj -> ((RoomType) obj[0]).getId().equals(roomTypeId))
                .anyMatch(obj -> ((Number) obj[1]).intValue() >= numberOfRooms);
    }

    private HomestayResponse convertToHomestayResponse(Homestay homestay) {
        return HomestayResponse.builder()
                .id(homestay.getId())
                .name(homestay.getName())
                .address(homestay.getAddress())
                .pricePerNight(homestay.getMinPrice())
                .stars(homestay.getStarRating())
                .rating(homestay.getAverageRating() != null ? homestay.getAverageRating().doubleValue() : null)
                .numOfReviews(homestay.getReviewCount())
                .thumbnail(homestay.getThumbnail())
                .destinationId(homestay.getDestination() != null ? homestay.getDestination().getId() : null)
                .destinationName(homestay.getDestination() != null ? homestay.getDestination().getName() : null)
                .phone(homestay.getPhone())
                .email(homestay.getEmail())
                .description(homestay.getDescription())
                .amenities(convertAmenitiesToList(homestay.getAmenities()))
                .totalRooms(homestay.getTotalRooms())
                .availableRooms(homestay.getAvailableRooms())
                .latitude(homestay.getLatitude())
                .longitude(homestay.getLongitude())
                .build();
    }

    /**
     * Lấy danh sách homestay có doanh thu cao nhất (top revenue)
     * Sử dụng InvoiceRepository.getTopHomestaysByRevenue() để lấy theo tổng commission
     */
    @Transactional(readOnly = true)
    public List<HomestayResponse> getTopHomestaysByRevenue(Integer limit) {
        List<Object[]> topHomestays = invoiceRepository.getTopHomestaysByRevenue();

        // Lấy danh sách homestay IDs từ kết quả (giới hạn theo limit)
        List<Long> homestayIds = topHomestays.stream()
                .limit(limit)
                .map(obj -> (Long) obj[0])
                .collect(Collectors.toList());

        List<HomestayResponse> result = new ArrayList<>();

        if (!homestayIds.isEmpty()) {
            // Lấy chi tiết homestay từ DB
            List<Homestay> homestays = hotelRepository.findAllById(homestayIds);

            // Sắp xếp lại theo thứ tự doanh thu (giữ nguyên thứ tự từ query)
            Map<Long, Homestay> homestayMap = homestays.stream()
                    .collect(Collectors.toMap(Homestay::getId, h -> h));

            result.addAll(homestayIds.stream()
                    .map(homestayMap::get)
                    .filter(h -> h != null && Boolean.TRUE.equals(h.getIsActive()))
                    .map(this::convertToHomestayResponse)
                    .collect(Collectors.toList()));
        }

        // Nếu danh sách homestay có doanh thu chưa đủ (ví dụ database ít hóa đơn)
        // thì lấy thêm các homestay có rating cao nhất để bù vào cho đủ số lượng (limit)
        if (result.size() < limit) {
            List<Long> existingIds = result.stream().map(HomestayResponse::getId).collect(Collectors.toList());
            Pageable pageable = PageRequest.of(0, limit);
            Page<Homestay> fallbackHomestays = hotelRepository.findTopByOrderByAverageRatingDesc(pageable);
            
            for (Homestay h : fallbackHomestays) {
                if (result.size() >= limit) break;
                if (!existingIds.contains(h.getId()) && Boolean.TRUE.equals(h.getIsActive())) {
                    result.add(convertToHomestayResponse(h));
                }
            }
        }

        return result;
    }

}