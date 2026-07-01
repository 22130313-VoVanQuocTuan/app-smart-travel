package com.example.smart_travel_BE.dto.invoice.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RefundRequest {

    @NotNull(message = "Booking ID không được để trống")
    @Positive(message = "Booking ID phải là số dương")
    private Long bookingId;

    @NotBlank(message = "Lý do hoàn tiền không được để trống")
    @Size(max = 1000, message = "LÃ½ do hoÃ n tiá»n tá»‘i Ä‘a 1000 kÃ½ tá»±")
    private String reason;

    @Size(max = 150, message = "TÃªn ngÃ¢n hÃ ng tá»‘i Ä‘a 150 kÃ½ tá»±")
    private String refundBankName;

    @Size(max = 150, message = "Chi nhÃ¡nh ngÃ¢n hÃ ng tá»‘i Ä‘a 150 kÃ½ tá»±")
    private String refundBankBranch;

    @Size(max = 50, message = "Sá»‘ tÃ i khoáº£n tá»‘i Ä‘a 50 kÃ½ tá»±")
    private String refundAccountNumber;

    @Size(max = 150, message = "TÃªn chá»§ tÃ i khoáº£n tá»‘i Ä‘a 150 kÃ½ tá»±")
    private String refundAccountHolder;
}
