package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Entity.Invoice;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, UUID> {

    boolean existsByRoomIdAndInvoicePeriod(UUID roomId, LocalDate invoicePeriod);

    // UC27: Tìm các hóa đơn chưa khớp tiền mà ngày hạn chót nhỏ hơn ngày hôm nay
    List<Invoice> findByStatusAndDueDateLessThan(InvoiceStatus status, LocalDate date);

    // UC26: Tìm các hóa đơn chưa đóng tiền mà sắp đến hạn (Ví dụ: còn đúng 1 ngày hoặc chính là ngày hôm nay)
    List<Invoice> findByStatusAndDueDate(InvoiceStatus status, LocalDate date);

    void deleteAllByContractId(UUID contractId);

    List<Invoice> findByContractId(UUID contractId);
}