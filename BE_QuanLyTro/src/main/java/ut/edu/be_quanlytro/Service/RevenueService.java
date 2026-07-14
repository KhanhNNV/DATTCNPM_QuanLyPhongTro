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
        LocalDate normalizedMonth = month.withDayOfMonth(1);
        List<Invoice> invoices;

        if (areaId != null) {
            var area = areaRepository.findById(areaId)
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khu trọ!"));
            if (!area.getLandlord().getId().equals(landlordId)) {
                throw new AccessDeniedException("Bạn không có quyền xem báo cáo của khu trọ khác!");
            }
            invoices = invoiceRepository.findAllByAreaAndLandlordAndPeriod(areaId, landlordId, normalizedMonth);
        } else {
            invoices = invoiceRepository.findAllByLandlordAndPeriod(landlordId, normalizedMonth);
        }

        long totalInvoices = invoices.size();

        long paidCount = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PAID)
                .count();

        BigDecimal totalCollected = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PAID)
                .map(Invoice::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long pendingCount = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PENDING)
                .count();

        BigDecimal totalPending = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.PENDING)
                .map(Invoice::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long unpaidCount = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.UNPAID || i.getStatus() == InvoiceStatus.OVERDUE)
                .count();

        BigDecimal totalDebt = invoices.stream()
                .filter(i -> i.getStatus() == InvoiceStatus.UNPAID || i.getStatus() == InvoiceStatus.OVERDUE)
                .map(Invoice::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return RevenueReportResponse.builder()
                .period(normalizedMonth)
                .totalInvoices(totalInvoices)
                .paidInvoicesCount(paidCount)
                .pendingInvoicesCount(pendingCount)
                .unpaidInvoicesCount(unpaidCount)
                .totalCollectedAmount(totalCollected)
                .totalPendingAmount(totalPending)
                .totalDebtAmount(totalDebt)
                .build();
    }
}