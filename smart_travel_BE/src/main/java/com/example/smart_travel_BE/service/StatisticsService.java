package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.statistics.DashboardStatsResponse;
import com.example.smart_travel_BE.dto.statistics.RevenueByCategoryResponse;
import com.example.smart_travel_BE.dto.statistics.RevenueResponse;
import com.example.smart_travel_BE.entity.Destination;
import com.example.smart_travel_BE.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class StatisticsService {

    private final UserRepository userRepository;
    private final ProvinceRepository provinceRepository;
    private final DestinationRepository destinationRepository;
    private final HomestayRepository homestayRepository;
    private final TourRepository tourRepository;
    private final VoucherRepository voucherRepository;
    private final InvoiceRepository invoiceRepository;

    /**
     * Lấy thống kê tổng quan cho Admin Dashboard
     */
    public DashboardStatsResponse getDashboardStats() {
        LocalDate today = LocalDate.now();

        // Đếm người dùng theo vai trò
        int totalUsers = (int) userRepository.count();
        int userCount = (int) userRepository.countByRole("USER");
        int hostCount = (int) userRepository.countByRole("HOST");
        int adminCount = (int) userRepository.countByRole("ADMIN");

        // Đếm số lượng
        int totalProvinces = (int) provinceRepository.count();
        int totalDestinations = (int) destinationRepository.count();
        int totalHotels = (int) homestayRepository.count();
        int totalTours = (int) tourRepository.count();
        int totalVouchers = (int) voucherRepository.count();

        // Thống kê today
        int todayInvoices = (int) invoiceRepository.countByIssueDate(today);
        BigDecimal todayRevenue = invoiceRepository.sumTotalAmountByDate(today);
        BigDecimal totalRevenue = invoiceRepository.sumTotalAmount();

        // Top địa điểm được nhiều lượt xem
        List<Destination> topDests = destinationRepository.findAll(
                PageRequest.of(0, 5, Sort.by(Sort.Direction.DESC, "viewCount"))
        ).getContent();

        List<DashboardStatsResponse.TopDestinationDTO> topDestinations = topDests.stream()
                .map(d -> DashboardStatsResponse.TopDestinationDTO.builder()
                        .id(d.getId())
                        .name(d.getName())
                        .viewCount(d.getViewCount())
                        .provinceName(d.getProvince() != null ? d.getProvince().getName() : "N/A")
                        .build())
                .collect(Collectors.toList());

        return DashboardStatsResponse.builder()
                .totalUsers(totalUsers)
                .totalUsersByRoleUSER(userCount)
                .totalUsersByRoleHOST(hostCount)
                .totalUsersByRoleADMIN(adminCount)
                .totalProvinces(totalProvinces)
                .totalDestinations(totalDestinations)
                .totalHotels(totalHotels)
                .totalTours(totalTours)
                .totalVouchers(totalVouchers)
                .todayInvoices(todayInvoices)
                .todayRevenue(todayRevenue != null ? todayRevenue : BigDecimal.ZERO)
                .totalRevenue(totalRevenue != null ? totalRevenue : BigDecimal.ZERO)
                .topDestinations(topDestinations)
                .build();
    }

    /**
     * Thống kê tổng quan cho Host Dashboard
     */
    public DashboardStatsResponse getHostDashboardStats(Long hostId) {
        LocalDate today = LocalDate.now();

        // Đếm số lượng homestay của host
        int totalHotels = (int) homestayRepository.countByOwnerIdAndIsActiveTrue(hostId);

        // Tính doanh thu và hóa đơn hôm nay
        BigDecimal todayRevenue = invoiceRepository.sumHostRevenueByDate(hostId, today);
        int todayInvoices = (int) invoiceRepository.countHostInvoicesByDate(hostId, today);

        // Tổng doanh thu của host
        BigDecimal totalRevenue = invoiceRepository.sumTotalHostRevenue(hostId);

        return DashboardStatsResponse.builder()
                .totalHotels(totalHotels)
                .todayInvoices(todayInvoices)
                .todayRevenue(todayRevenue)
                .totalRevenue(totalRevenue)
                .build();
    }

    /**
     * Doanh thu hệ thống theo ngày/tháng/năm
     */
    public RevenueResponse getSystemRevenue(String type, int year, int month) {
        List<RevenueResponse.RevenueDataPoint> dataPoints = new ArrayList<>();
        BigDecimal totalRevenue = BigDecimal.ZERO;

        switch (type.toUpperCase()) {
            case "DAY":
                List<Object[]> dayData = invoiceRepository.getSystemRevenueByDay(year, month);
                for (Object[] row : dayData) {
                    int day = ((Number) row[0]).intValue();
                    BigDecimal revenue = toBigDecimal(row[1]);
                    BigDecimal homestayAmt = toBigDecimal(row[2]);
                    BigDecimal commissionAmt = toBigDecimal(row[3]);
                    long count = ((Number) row[4]).longValue();
                    totalRevenue = totalRevenue.add(commissionAmt); // Admin total is commission

                    dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                            .label(String.format("%02d/%02d", day, month))
                            .revenue(commissionAmt) // Admin revenue is commission
                            .homestayAmount(homestayAmt)
                            .commissionAmount(commissionAmt)
                            .invoiceCount(count)
                            .build());
                }
                break;

            case "MONTH":
                List<Object[]> monthData = invoiceRepository.getSystemRevenueByMonth(year);
                for (Object[] row : monthData) {
                    int m = ((Number) row[0]).intValue();
                    BigDecimal revenue = toBigDecimal(row[1]);
                    BigDecimal homestayAmt = toBigDecimal(row[2]);
                    BigDecimal commissionAmt = toBigDecimal(row[3]);
                    long count = ((Number) row[4]).longValue();
                    totalRevenue = totalRevenue.add(commissionAmt); // Admin total is commission

                    dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                            .label("T" + m)
                            .revenue(commissionAmt) // Admin revenue is commission
                            .homestayAmount(homestayAmt)
                            .commissionAmount(commissionAmt)
                            .invoiceCount(count)
                            .build());
                }
                break;

            case "YEAR":
                List<Object[]> yearData = invoiceRepository.getSystemRevenueByYear();
                for (Object[] row : yearData) {
                    int y = ((Number) row[0]).intValue();
                    BigDecimal revenue = toBigDecimal(row[1]);
                    BigDecimal homestayAmt = toBigDecimal(row[2]);
                    BigDecimal commissionAmt = toBigDecimal(row[3]);
                    long count = ((Number) row[4]).longValue();
                    totalRevenue = totalRevenue.add(commissionAmt); // Admin total is commission

                    dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                            .label(String.valueOf(y))
                            .revenue(commissionAmt) // Admin revenue is commission
                            .homestayAmount(homestayAmt)
                            .commissionAmount(commissionAmt)
                            .invoiceCount(count)
                            .build());
                }
                break;
        }

        return RevenueResponse.builder()
                .type(type.toUpperCase())
                .totalRevenue(totalRevenue)
                .dataPoints(dataPoints)
                .build();
    }

    /**
     * Doanh thu của Host theo ngày/tháng/năm
     */
    public RevenueResponse getHostRevenue(Long hostId, String type, int year, int month) {
        List<RevenueResponse.RevenueDataPoint> dataPoints = new ArrayList<>();
        BigDecimal totalRevenue = BigDecimal.ZERO;

        switch (type.toUpperCase()) {
            case "DAY":
                List<Object[]> dayData = invoiceRepository.getHostRevenueByDay(hostId, year, month);
                for (Object[] row : dayData) {
                    int day = ((Number) row[0]).intValue();
                    BigDecimal homestayAmt = toBigDecimal(row[1]);
                    BigDecimal commissionAmt = toBigDecimal(row[2]);
                    long count = ((Number) row[3]).longValue();
                    totalRevenue = totalRevenue.add(homestayAmt);

                    dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                            .label(String.format("%02d/%02d", day, month))
                            .revenue(homestayAmt)
                            .homestayAmount(homestayAmt)
                            .commissionAmount(commissionAmt)
                            .invoiceCount(count)
                            .build());
                }
                break;

            case "MONTH":
                List<Object[]> monthData = invoiceRepository.getHostRevenueByMonth(hostId, year);
                for (Object[] row : monthData) {
                    int m = ((Number) row[0]).intValue();
                    BigDecimal homestayAmt = toBigDecimal(row[1]);
                    BigDecimal commissionAmt = toBigDecimal(row[2]);
                    long count = ((Number) row[3]).longValue();
                    totalRevenue = totalRevenue.add(homestayAmt);

                    dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                            .label("T" + m)
                            .revenue(homestayAmt)
                            .homestayAmount(homestayAmt)
                            .commissionAmount(commissionAmt)
                            .invoiceCount(count)
                            .build());
                }
                break;

            case "YEAR":
                List<Object[]> yearData = invoiceRepository.getHostRevenueByYear(hostId);
                for (Object[] row : yearData) {
                    int y = ((Number) row[0]).intValue();
                    BigDecimal homestayAmt = toBigDecimal(row[1]);
                    BigDecimal commissionAmt = toBigDecimal(row[2]);
                    long count = ((Number) row[3]).longValue();
                    totalRevenue = totalRevenue.add(homestayAmt);

                    dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                            .label(String.valueOf(y))
                            .revenue(homestayAmt)
                            .homestayAmount(homestayAmt)
                            .commissionAmount(commissionAmt)
                            .invoiceCount(count)
                            .build());
                }
                break;
        }

        return RevenueResponse.builder()
                .type(type.toUpperCase())
                .totalRevenue(totalRevenue)
                .dataPoints(dataPoints)
                .build();
    }

    /**
     * Doanh thu host theo khoảng thời gian tuỳ chọn (cho biểu đồ cột)
     */
    public RevenueResponse getHostRevenueByRange(Long hostId, LocalDate startDate, LocalDate endDate) {
        List<Object[]> rangeData = invoiceRepository.getHostRevenueByDateRange(hostId, startDate, endDate);
        List<RevenueResponse.RevenueDataPoint> dataPoints = new ArrayList<>();
        BigDecimal totalRevenue = BigDecimal.ZERO;
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM");

        for (Object[] row : rangeData) {
            LocalDate date = (LocalDate) row[0];
            BigDecimal homestayAmt = toBigDecimal(row[1]);
            long count = ((Number) row[2]).longValue();
            totalRevenue = totalRevenue.add(homestayAmt);

            dataPoints.add(RevenueResponse.RevenueDataPoint.builder()
                    .label(date.format(fmt))
                    .revenue(homestayAmt)
                    .homestayAmount(homestayAmt)
                    .commissionAmount(BigDecimal.ZERO)
                    .invoiceCount(count)
                    .build());
        }

        return RevenueResponse.builder()
                .type("RANGE")
                .totalRevenue(totalRevenue)
                .dataPoints(dataPoints)
                .build();
    }

    /**
     * Doanh thu host phân theo từng Homestay trong 1 tháng (cho biểu đồ tròn)
     */
    public RevenueByCategoryResponse getHostRevenueByCategory(Long hostId, int year, int month) {
        List<Object[]> catData = invoiceRepository.getHostRevenueByCategoryInMonth(hostId, year, month);
        BigDecimal totalRevenue = BigDecimal.ZERO;
        List<RevenueByCategoryResponse.CategoryRevenueItem> items = new ArrayList<>();

        // Tính tổng
        for (Object[] row : catData) {
            BigDecimal revenue = toBigDecimal(row[2]);
            totalRevenue = totalRevenue.add(revenue);
        }

        // Tính phần trăm
        for (Object[] row : catData) {
            Long homestayId = ((Number) row[0]).longValue();
            String homestayName = (String) row[1];
            BigDecimal revenue = toBigDecimal(row[2]);
            long count = ((Number) row[3]).longValue();

            double percentage = totalRevenue.compareTo(BigDecimal.ZERO) > 0
                    ? revenue.multiply(BigDecimal.valueOf(100))
                              .divide(totalRevenue, 2, RoundingMode.HALF_UP)
                              .doubleValue()
                    : 0.0;

            items.add(RevenueByCategoryResponse.CategoryRevenueItem.builder()
                    .homestayId(homestayId)
                    .homestayName(homestayName)
                    .revenue(revenue)
                    .invoiceCount(count)
                    .percentage(percentage)
                    .build());
        }

        return RevenueByCategoryResponse.builder()
                .year(year)
                .month(month)
                .totalRevenue(totalRevenue)
                .categories(items)
                .build();
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return BigDecimal.ZERO;
        if (value instanceof BigDecimal) return (BigDecimal) value;
        return new BigDecimal(value.toString());
    }
}
