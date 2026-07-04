package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Enum.PaymentStatus;
import ut.edu.be_quanlytro.Entity.Payment;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, UUID> {

    // Tìm giao dịch đang chờ duyệt (PENDING) mới nhất của một hóa đơn
    Optional<Payment> findFirstByInvoiceIdAndStatusOrderByCreatedAtDesc(UUID invoiceId, PaymentStatus status);
    void deleteAllByInvoiceId(UUID invoiceId);
}