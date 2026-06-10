package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Invoice;

import java.time.LocalDate;
import java.util.UUID;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, UUID> {

    boolean existsByRoomIdAndInvoicePeriod(UUID roomId, LocalDate invoicePeriod);
}