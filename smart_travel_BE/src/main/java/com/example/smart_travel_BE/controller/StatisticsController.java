package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.statistics.DashboardStatsResponse;
import com.example.smart_travel_BE.dto.statistics.RevenueByCategoryResponse;
import com.example.smart_travel_BE.dto.statistics.RevenueResponse;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/admin/statistics")
@RequiredArgsConstructor
@Slf4j
public class StatisticsController {

    private final StatisticsService statisticsService;

    /**
     * Thống kê tổng quan cho Admin Dashboard
     */
    @GetMapping("/dashboard")
    public ResponseEntity<APIResponse<DashboardStatsResponse>> getDashboardStats() {
        try {
            DashboardStatsResponse stats = statisticsService.getDashboardStats();
            return ResponseEntity.ok(
                    APIResponse.<DashboardStatsResponse>builder()
                            .msg("Lấy thống kê dashboard thành công")
                            .data(stats)
                            .build()
            );
        } catch (Exception e) {
            log.error("Error getting dashboard stats", e);
            return ResponseEntity.internalServerError().body(
                    APIResponse.<DashboardStatsResponse>builder()
                            .msg("Lỗi khi lấy thống kê: " + e.getMessage())
                            .build()
            );
        }
    }

    /**
     * Doanh thu hệ thống theo ngày/tháng/năm
     */
    @GetMapping("/revenue")
    public ResponseEntity<APIResponse<RevenueResponse>> getSystemRevenue(
            @RequestParam(defaultValue = "MONTH") String type,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        try {
            int y = year != null ? year : LocalDate.now().getYear();
            int m = month != null ? month : LocalDate.now().getMonthValue();

            RevenueResponse revenue = statisticsService.getSystemRevenue(type, y, m);
            return ResponseEntity.ok(
                    APIResponse.<RevenueResponse>builder()
                            .msg("Lấy doanh thu hệ thống thành công")
                            .data(revenue)
                            .build()
            );
        } catch (Exception e) {
            log.error("Error getting system revenue", e);
            return ResponseEntity.internalServerError().body(
                    APIResponse.<RevenueResponse>builder()
                            .msg("Lỗi khi lấy doanh thu: " + e.getMessage())
                            .build()
            );
        }
    }

    /**
     * Doanh thu của Host theo ngày/tháng/năm
     */
    @GetMapping("/host-revenue")
    public ResponseEntity<APIResponse<RevenueResponse>> getHostRevenue(
            @RequestParam Long hostId,
            @RequestParam(defaultValue = "MONTH") String type,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        try {
            int y = year != null ? year : LocalDate.now().getYear();
            int m = month != null ? month : LocalDate.now().getMonthValue();

            RevenueResponse revenue = statisticsService.getHostRevenue(hostId, type, y, m);
            return ResponseEntity.ok(
                    APIResponse.<RevenueResponse>builder()
                            .msg("Lấy doanh thu host thành công")
                            .data(revenue)
                            .build()
            );
        } catch (Exception e) {
            log.error("Error getting host revenue", e);
            return ResponseEntity.internalServerError().body(
                    APIResponse.<RevenueResponse>builder()
                            .msg("Lỗi khi lấy doanh thu host: " + e.getMessage())
                            .build()
            );
        }
    }

    /**
     * Doanh thu host theo khoảng thời gian tuỳ chọn (biểu đồ cột)
     */
    @GetMapping("/host-revenue-by-range")
    public ResponseEntity<APIResponse<RevenueResponse>> getHostRevenueByRange(
            @RequestParam Long hostId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        try {
            RevenueResponse revenue = statisticsService.getHostRevenueByRange(hostId, startDate, endDate);
            return ResponseEntity.ok(
                    APIResponse.<RevenueResponse>builder()
                            .msg("Lấy doanh thu theo khoảng thời gian thành công")
                            .data(revenue)
                            .build()
            );
        } catch (Exception e) {
            log.error("Error getting host revenue by range", e);
            return ResponseEntity.internalServerError().body(
                    APIResponse.<RevenueResponse>builder()
                            .msg("Lỗi khi lấy doanh thu: " + e.getMessage())
                            .build()
            );
        }
    }

    /**
     * Doanh thu host phân theo từng Homestay trong 1 tháng (biểu đồ tròn)
     */
    @GetMapping("/host-revenue-by-category")
    public ResponseEntity<APIResponse<RevenueByCategoryResponse>> getHostRevenueByCategory(
            @RequestParam Long hostId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        try {
            int y = year != null ? year : LocalDate.now().getYear();
            int m = month != null ? month : LocalDate.now().getMonthValue();

            RevenueByCategoryResponse revenue = statisticsService.getHostRevenueByCategory(hostId, y, m);
            return ResponseEntity.ok(
                    APIResponse.<RevenueByCategoryResponse>builder()
                            .msg("Lấy doanh thu theo danh mục thành công")
                            .data(revenue)
                            .build()
            );
        } catch (Exception e) {
            log.error("Error getting host revenue by category", e);
            return ResponseEntity.internalServerError().body(
                    APIResponse.<RevenueByCategoryResponse>builder()
                            .msg("Lỗi khi lấy doanh thu theo danh mục: " + e.getMessage())
                            .build()
            );
        }
    }
}
