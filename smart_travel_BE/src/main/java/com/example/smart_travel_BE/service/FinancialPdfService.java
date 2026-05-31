package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.finance.FinanceSummaryDTO;
import com.example.smart_travel_BE.dto.finance.RevenueChartDTO;
import com.lowagie.text.*;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;

@Service
public class FinancialPdfService {

    public byte[] generate(
            FinanceSummaryDTO summary,
            List<RevenueChartDTO> monthlyRevenue,
            int year
    ) {

        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document document = new Document(PageSize.A4, 36, 36, 36, 36);
            PdfWriter.getInstance(document, out);
            document.open();

            FontFactory.registerDirectories();
            Font titleFont = createFont(18, Font.BOLD);
            Font headerFont = createFont(12, Font.BOLD);
            Font normalFont = createFont(11, Font.NORMAL);

            document.add(new Paragraph("Báo cáo dòng tiền", titleFont));
            document.add(new Paragraph("Năm: " + year, normalFont));
            document.add(new Paragraph(" "));

            PdfPTable summaryTable = new PdfPTable(2);
            summaryTable.setWidthPercentage(100);
            summaryTable.setSpacingBefore(8);
            summaryTable.setSpacingAfter(12);
            summaryTable.addCell(new Phrase("Mục", headerFont));
            summaryTable.addCell(new Phrase("Giá trị", headerFont));
            summaryTable.addCell(new Phrase("Doanh thu tổng", normalFont));
            summaryTable.addCell(new Phrase(formatMoney(summary.getTotalRevenue()), normalFont));
            summaryTable.addCell(new Phrase("Hoa hồng", normalFont));
            summaryTable.addCell(new Phrase(formatMoney(summary.getTotalCommission()), normalFont));
            summaryTable.addCell(new Phrase("Thanh toán homestay", normalFont));
            summaryTable.addCell(new Phrase(formatMoney(summary.getTotalHomestayRevenue()), normalFont));
            summaryTable.addCell(new Phrase("Tổng hóa đơn", normalFont));
            summaryTable.addCell(new Phrase(String.valueOf(summary.getTotalInvoices()), normalFont));
            summaryTable.addCell(new Phrase("Tổng booking", normalFont));
            summaryTable.addCell(new Phrase(String.valueOf(summary.getTotalBookings()), normalFont));
            document.add(summaryTable);

            BigDecimal totalCashIn = summary.getTotalRevenue();
            BigDecimal totalCashOut = summary.getTotalCommission().add(summary.getTotalHomestayRevenue());
            BigDecimal netCash = totalCashIn.subtract(totalCashOut);

            PdfPTable cashFlowTable = new PdfPTable(2);
            cashFlowTable.setWidthPercentage(100);
            cashFlowTable.setSpacingBefore(8);
            cashFlowTable.setSpacingAfter(12);
            cashFlowTable.addCell(new Phrase("Dòng tiền", headerFont));
            cashFlowTable.addCell(new Phrase("Giá trị", headerFont));
            cashFlowTable.addCell(new Phrase("Tổng tiền vào", normalFont));
            cashFlowTable.addCell(new Phrase(formatMoney(totalCashIn), normalFont));
            cashFlowTable.addCell(new Phrase("Tổng tiền ra", normalFont));
            cashFlowTable.addCell(new Phrase(formatMoney(totalCashOut), normalFont));
            cashFlowTable.addCell(new Phrase("Dòng tiền thuần", normalFont));
            cashFlowTable.addCell(new Phrase(formatMoney(netCash), normalFont));
            document.add(cashFlowTable);

            if (!monthlyRevenue.isEmpty()) {
                document.add(new Paragraph("Biểu đồ doanh thu theo tháng", headerFont));
                PdfPTable monthlyTable = new PdfPTable(4);
                monthlyTable.setWidthPercentage(100);
                monthlyTable.setSpacingBefore(8);
                monthlyTable.addCell(new Phrase("Tháng", headerFont));
                monthlyTable.addCell(new Phrase("Doanh thu", headerFont));
                monthlyTable.addCell(new Phrase("Hoa hồng", headerFont));
                monthlyTable.addCell(new Phrase("Homestay", headerFont));

                for (RevenueChartDTO row : monthlyRevenue) {
                    monthlyTable.addCell(new Phrase(row.getLabel(), normalFont));
                    monthlyTable.addCell(new Phrase(formatMoney(row.getTotalRevenue()), normalFont));
                    monthlyTable.addCell(new Phrase(formatMoney(row.getCommissionRevenue()), normalFont));
                    monthlyTable.addCell(new Phrase(formatMoney(row.getHomestayRevenue()), normalFont));
                }

                document.add(monthlyTable);
            }

            document.close();
            return out.toByteArray();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    private String formatMoney(BigDecimal value) {
        NumberFormat format = NumberFormat.getNumberInstance(new Locale("vi", "VN"));
        return format.format(value) + " đ";
    }

    private Font createFont(float size, int style) {
        String[] candidates = {
            "Arial Unicode MS",
            "Tahoma",
            "DejaVu Sans",
            "Noto Sans",
            "Liberation Sans",
            FontFactory.HELVETICA
        };

        for (String fontName : candidates) {
            try {
                if (fontName.equals(FontFactory.HELVETICA)) {
                    return FontFactory.getFont(FontFactory.HELVETICA, size, style);
                }
                Font font = FontFactory.getFont(fontName, BaseFont.IDENTITY_H, BaseFont.EMBEDDED, size, style);
                if (font != null) {
                    return font;
                }
            } catch (Exception ignored) {
            }
        }

        return FontFactory.getFont(FontFactory.HELVETICA, size, style);
    }
}