package ut.edu.be_quanlytro.Dto.Response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
public class RevenueReportResponse {
    private LocalDate period;               // Tháng thống kê (đã quy về ngày 1)
    private long totalInvoices;             // Tổng số lượng hóa đơn phát sinh trong tháng
    private long paidInvoicesCount;         // Số lượng hóa đơn ĐÃ THU
    private long unpaidInvoicesCount;       // Số lượng hóa đơn CÒN NỢ (Gồm UNPAID và OVERDUE)
    private BigDecimal totalCollectedAmount; // Tổng số tiền ĐÃ THU (Đã thanh toán)
    private BigDecimal totalDebtAmount;      // Tổng số tiền CÒN NỢ (Nợ xấu)
}