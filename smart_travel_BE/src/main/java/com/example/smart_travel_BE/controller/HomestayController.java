package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.hotel.request.HomestayFilterRequest;
import com.example.smart_travel_BE.dto.hotel.response.HomestayResponse;
import com.example.smart_travel_BE.service.HomestayService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/v1/hotels")
public class HomestayController {

    @Autowired
    private HomestayService hotelService;

    @GetMapping
    // Lấy danh sách khách sạn theo địa điểm (destination)
    public Page<HomestayResponse> getHotels(
            @RequestParam(required = false) Long destinationId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer minStars,
            @RequestParam(required = false) Integer maxStars,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String city,
            @RequestParam(required = false, defaultValue = "0") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size,
            @RequestParam(required = false, defaultValue = "pricePerNight") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String sortDir
    ) {
        HomestayFilterRequest req = new HomestayFilterRequest();
        req.setDestinationId(destinationId);
        req.setKeyword(keyword);
        req.setMinStars(minStars);
        req.setMaxStars(maxStars);
        if (minPrice != null) req.setMinPrice(BigDecimal.valueOf(minPrice));
        if (maxPrice != null) req.setMaxPrice(BigDecimal.valueOf(maxPrice));
        req.setCity(city);
        req.setPage(page);
        req.setSize(size);
        req.setSortBy(sortBy);
        req.setSortDir(sortDir);

        return hotelService.getHotels(req);
    }
}