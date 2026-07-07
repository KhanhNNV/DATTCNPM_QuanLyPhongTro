package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Response.RevenueReportResponse;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Entity.Invoice;
import ut.edu.be_quanlytro.Repository.AreaRepository;
import ut.edu.be_quanlytro.Repository.InvoiceRepository;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RevenueService {

    private final InvoiceRepository invoiceRepository;
    private final AreaRepository areaRepository;

    public RevenueReportResponse getMonthlyRevenueReport(LocalDate month, UUID areaId, UUID landlordId) {
        // Chuẩn hóa ngày về ngày đầu tháng để khớp với dữ liệu chốt hóa đơn
        LocalDate normalizedMonth = month.withDayOfMonth(1);
        List<Invoice> invoices;

        // 1. Kiểm tra luồng filter: Xem tất cả hay xem theo từng Khu trọ cụ thể
        if (areaId != null) {
            // Chốt chặn bảo mật: Kiểm tra xem khu trọ này có đúng của ông chủ trọ đang gọi API không
            var area = areaRepository.findById(areaId)
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khu trọ!"));
            if (!area.getLandlord().getId().equals(landlordId)) {
                throw new AccessDeniedException("Bạn không có quyền xem báo cáo của khu trọ khác!");
            }
            invoices = invoiceRepository.findAllByAreaAndLandlordAndPeriod(areaId, landlordId, normalizedMonth);
        } else {
            invoices = invoiceRepository.findAllByLandlordAndPeriod(landlordId, normalizedMonth);
        }

        // 2. Dùng Stream tính toán thần tốc các chỉ số
        long totalInvoices = invoices.size();

        long paidCount = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PAID)
                .count();

        long unpaidCount = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.UNPAID || i.getStatus() == InvoiceStatus.OVERDUE)
                .count();

        // Tính tổng tiền ĐÃ THU
        BigDecimal totalCollected = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PAID)
                .map(Invoice::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Tính tổng tiền CÒN NỢ (Nợ xấu)
        BigDecimal totalDebt = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.UNPAID || i.getStatus() == InvoiceStatus.OVERDUE)
                .map(Invoice::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 3. Đóng gói trả về DTO siêu đẹp
        return RevenueReportResponse.builder()
                .period(normalizedMonth)
                .totalInvoices(totalInvoices)
                .paidInvoicesCount(paidCount)
                .unpaidInvoicesCount(unpaidCount)
                .totalCollectedAmount(totalCollected)
                .totalDebtAmount(totalDebt)
                .build();
    }
}