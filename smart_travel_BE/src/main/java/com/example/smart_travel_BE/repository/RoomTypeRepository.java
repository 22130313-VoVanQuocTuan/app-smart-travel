package com.example.smart_travel_BE.repository;

import com.example.smart_travel_BE.entity.RoomType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;



@Repository
public interface RoomTypeRepository extends JpaRepository<RoomType, Long> {
}