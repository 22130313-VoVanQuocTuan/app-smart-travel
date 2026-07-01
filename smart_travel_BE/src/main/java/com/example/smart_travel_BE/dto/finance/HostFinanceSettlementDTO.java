package com.example.smart_travel_BE.dto.finance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HostFinanceSettlementDTO {

    private Long hostId;

    private String hostName;

    private Long totalCompletedBookings;

    private Long onlineCompletedBookings;

    private Long cashCompletedBookings;

    private BigDecimal totalCompletedRevenue;

    private BigDecimal onlineCompletedRevenue;

    private BigDecimal cashCompletedRevenue;

    private BigDecimal amountPayableToHost;

    private BigDecimal amountHostMustTransfer;

    private BigDecimal totalCommission;

    private Long homestayCount;
}
