// service/TourService.java
package com.example.smart_travel_BE.service;

import com.cloudinary.Cloudinary;
import com.example.smart_travel_BE.dto.tour.request.TourCreateRequest;
import com.example.smart_travel_BE.dto.tour.request.TourScheduleRequest;
import com.example.smart_travel_BE.dto.tour.response.TourResponse;
import com.example.smart_travel_BE.entity.*;
import com.example.smart_travel_BE.exception.AppException;
import com.example.smart_travel_BE.exception.ErrorCode;
import com.example.smart_travel_BE.repository.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TourService {

    private final TourRepository tourRepository;
    private final HomestayRepository homestayRepository;
    private final UserRepository userRepository;
    private final ObjectMapper mapper;
    @Autowired
    private CloudinaryService cloudinaryService;

    // Lấy tour theo homestay
    public List<TourResponse> getToursByHomestay(Long homestayId) {
        validateHomestayOwnership(homestayId);
        List<Tour> tours = tourRepository.findByHomestayIdAndIsActiveTrue(homestayId);
        return tours.stream().map(this::convertToResponse).collect(Collectors.toList());
    }

    // Tạo tour mới
    @Transactional
    public TourResponse createTour(TourCreateRequest request) throws Exception {
        validateHomestayOwnership(request.getHomestayId());

        Homestay homestay = homestayRepository.findById(request.getHomestayId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        User owner = getCurrentUser();

        Tour tour = new Tour();
        tour.setName(request.getName());
        tour.setDescription(request.getDescription());
        tour.setDurationDays(request.getDurationDays());
        tour.setDurationNights(request.getDurationNights());
        tour.setPricePerPerson(request.getPricePerPerson());
        tour.setMaxPeople(request.getMaxPeople());
        tour.setMinPeople(request.getMinPeople());
        tour.setIncluded(mapper.writeValueAsString(request.getIncluded()));
        tour.setExcluded(mapper.writeValueAsString(request.getExcluded()));
        tour.setHomestay(homestay);
        tour.setOwner(owner);
        tour.setIsActive(true);
        tour.setImages(new ArrayList<>());
        tour.setSchedules(new ArrayList<>());

        int order = 0;

        // Upload ảnh
        if (request.getThumbnail() != null && !request.getThumbnail().isEmpty()) {
            String thumbnailUrl = cloudinaryService.uploadFile(request.getThumbnail(), "tours/thumbnails");
            TourImage thumb = new TourImage();
            thumb.setTour(tour);
            thumb.setImageUrl(thumbnailUrl);
            thumb.setIsPrimary(true);
            thumb.setDisplayOrder(0);
            tour.getImages().add(thumb);
        }

        if (request.getImages() != null && !request.getImages().isEmpty()) {
            for (MultipartFile file : request.getImages()) {
                if (file == null || file.isEmpty()) continue;
                String imageUrl = cloudinaryService.uploadFile(file, "tours/galleries");
                TourImage img = new TourImage();
                img.setTour(tour);
                img.setImageUrl(imageUrl);
                img.setIsPrimary(false);
                img.setDisplayOrder(order++);
                tour.getImages().add(img);
            }
        }

        // Thêm schedule
        if (request.getSchedules() != null) {
            for (TourScheduleRequest scheduleReq : request.getSchedules()) {
                TourSchedule schedule = new TourSchedule();
                schedule.setTour(tour);
                schedule.setDayNumber(scheduleReq.getDayNumber());
                schedule.setTitle(scheduleReq.getTitle());
                schedule.setActivities(scheduleReq.getActivities());
                schedule.setAccommodation(scheduleReq.getAccommodation());
                schedule.setMeals(mapper.writeValueAsString(scheduleReq.getMeals()));
                tour.getSchedules().add(schedule);
            }
        }

        tourRepository.save(tour);
        return convertToResponse(tour);
    }

    // Cập nhật tour
    @Transactional
    public TourResponse updateTour(Long id, TourCreateRequest request) throws Exception {
        Tour tour = tourRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.TOUR_NOT_FOUND));

        validateTourOwnership(tour);
        validateHomestayOwnership(request.getHomestayId());

        Homestay homestay = homestayRepository.findById(request.getHomestayId())
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));

        tour.setName(request.getName());
        tour.setDescription(request.getDescription());
        tour.setDurationDays(request.getDurationDays());
        tour.setDurationNights(request.getDurationNights());
        tour.setPricePerPerson(request.getPricePerPerson());
        tour.setMaxPeople(request.getMaxPeople());
        tour.setMinPeople(request.getMinPeople());
        tour.setIncluded(mapper.writeValueAsString(request.getIncluded()));
        tour.setExcluded(mapper.writeValueAsString(request.getExcluded()));
        tour.setHomestay(homestay);

        // Xử lý thumbnail mới
        if (request.getThumbnail() != null && !request.getThumbnail().isEmpty()) {
            // Xóa ảnh thumbnail cũ
            tour.getImages().stream()
                    .filter(TourImage::getIsPrimary)
                    .findFirst()
                    .ifPresent(old -> {
                        cloudinaryService.deleteFile(old.getImageUrl());
                        tour.getImages().remove(old);
                    });

            String thumbnailUrl = cloudinaryService.uploadFile(request.getThumbnail(), "tours/thumbnails");
            TourImage thumb = new TourImage();
            thumb.setTour(tour);
            thumb.setImageUrl(thumbnailUrl);
            thumb.setIsPrimary(true);
            thumb.setDisplayOrder(0);
            tour.getImages().add(thumb);
        }

        // Đồng bộ gallery ảnh cũ (nếu FE gửi syncGalleryImages = true)
        if (request.getSyncGalleryImages() != null && request.getSyncGalleryImages()) {
            Set<String> keepUrls = request.getKeepImageUrls() != null
                    ? new HashSet<>(request.getKeepImageUrls())
                    : Collections.emptySet();

            Iterator<TourImage> iterator = tour.getImages().iterator();
            while (iterator.hasNext()) {
                TourImage image = iterator.next();
                // Không xóa ảnh thumbnail
                if (Boolean.TRUE.equals(image.getIsPrimary())) {
                    continue;
                }
                // Xóa ảnh không có trong danh sách giữ lại
                if (!keepUrls.contains(image.getImageUrl())) {
                    cloudinaryService.deleteFile(image.getImageUrl());
                    iterator.remove();
                }
            }
        }

        //Upload gallery images mới
        if (request.getImages() != null && !request.getImages().isEmpty()) {
            int currentOrder = tour.getImages().size();
            for (MultipartFile file : request.getImages()) {
                if (file == null || file.isEmpty()) continue;
                String imageUrl = cloudinaryService.uploadFile(file, "tours/galleries");
                TourImage img = new TourImage();
                img.setTour(tour);
                img.setImageUrl(imageUrl);
                img.setIsPrimary(false);
                img.setDisplayOrder(currentOrder++);
                tour.getImages().add(img);
            }
        }

        // Xử lý schedules
        tour.getSchedules().clear();
        if (request.getSchedules() != null) {
            for (TourScheduleRequest scheduleReq : request.getSchedules()) {
                TourSchedule schedule = new TourSchedule();
                schedule.setTour(tour);
                schedule.setDayNumber(scheduleReq.getDayNumber());
                schedule.setTitle(scheduleReq.getTitle());
                schedule.setActivities(scheduleReq.getActivities());
                schedule.setAccommodation(scheduleReq.getAccommodation());
                schedule.setMeals(mapper.writeValueAsString(scheduleReq.getMeals() != null ? scheduleReq.getMeals() : new ArrayList<>()));
                tour.getSchedules().add(schedule);
            }
        }

        tourRepository.save(tour);
        return convertToResponse(tour);
    }

    // Xóa tour
    @Transactional
    public void deleteTour(Long id) {
        Tour tour = tourRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.TOUR_NOT_FOUND));
        validateTourOwnership(tour);
        tour.setIsActive(false);
        tourRepository.save(tour);
    }

    // Lấy chi tiết tour
    public TourResponse getTourDetail(Long id) {
        Tour tour = tourRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.TOUR_NOT_FOUND));
        return convertToResponse(tour);
    }

    // Helper methods
    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        // Lấy email từ Principal
        String email;
        if (auth.getPrincipal() instanceof User) {
            email = ((User) auth.getPrincipal()).getEmail();
        } else {
            email = auth.getName();
        }

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
    }
    private void validateHomestayOwnership(Long homestayId) {
        User currentUser = getCurrentUser();
        Homestay homestay = homestayRepository.findById(homestayId)
                .orElseThrow(() -> new AppException(ErrorCode.HOMESTAY_NOT_FOUND));
        if (!homestay.getOwner().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.NOT_OWNER);
        }
    }

    private void validateTourOwnership(Tour tour) {
        User currentUser = getCurrentUser();
        if (!tour.getOwner().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.NOT_OWNER);
        }
    }


    private TourResponse convertToResponse(Tour tour) {
        String thumbnail = tour.getImages().stream()
                .filter(TourImage::getIsPrimary)
                .findFirst()
                .map(TourImage::getImageUrl)
                .orElse(null);

        List<String> images = tour.getImages().stream()
                .map(TourImage::getImageUrl)
                .collect(Collectors.toList());

        List<TourResponse.TourScheduleResponse> schedules = tour.getSchedules().stream()
                .map(s -> TourResponse.TourScheduleResponse.builder()
                        .dayNumber(s.getDayNumber())
                        .title(s.getTitle())
                        .activities(s.getActivities())
                        .accommodation(s.getAccommodation())
                        .meals(parseJsonToList(s.getMeals()))
                        .build())
                .collect(Collectors.toList());

        return TourResponse.builder()
                .id(tour.getId())
                .name(tour.getName())
                .description(tour.getDescription())
                .durationDays(tour.getDurationDays())
                .durationNights(tour.getDurationNights())
                .pricePerPerson(tour.getPricePerPerson())
                .maxPeople(tour.getMaxPeople())
                .minPeople(tour.getMinPeople())
                .thumbnail(thumbnail)
                .images(images)
                .included(parseJsonToList(tour.getIncluded()))
                .excluded(parseJsonToList(tour.getExcluded()))
                .schedules(schedules)
                .homestayId(tour.getHomestay() != null ? tour.getHomestay().getId() : null)
                .homestayName(tour.getHomestay() != null ? tour.getHomestay().getName() : null)
                .build();
    }

    private List<String> parseJsonToList(String json) {
        if (json == null || json.isBlank()) return new ArrayList<>();
        try {
            return mapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }
}