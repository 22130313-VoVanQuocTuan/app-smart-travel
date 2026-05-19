package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.repository.RoomTypeRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/room-types")
public class RoomTypeController {

    private final RoomTypeRepository roomTypeRepository;

    public RoomTypeController(RoomTypeRepository roomTypeRepository) {
        this.roomTypeRepository = roomTypeRepository;
    }

    // RoomTypeController.java
    @GetMapping("/{roomTypeId}/availability")
    public ResponseEntity<Map<String, Object>> checkAvailability(
            @PathVariable Long roomTypeId,
            @RequestParam LocalDate checkIn,
            @RequestParam LocalDate checkOut) {

        int availableRooms = roomTypeRepository.countAvailableRooms(roomTypeId, checkIn, checkOut);

        Map<String, Object> response = new HashMap<>();
        response.put("availableRooms", availableRooms);
        response.put("roomTypeId", roomTypeId);

        return ResponseEntity.ok(response);
    }
}
