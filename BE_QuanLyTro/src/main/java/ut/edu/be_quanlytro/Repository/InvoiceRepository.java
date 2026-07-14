package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Enum.InvoiceStatus;
import ut.edu.be_quanlytro.Entity.Invoice;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, UUID> {

    boolean existsByRoomIdAndInvoicePeriod(UUID roomId, LocalDate invoicePeriod);

    List<Invoice> findByStatusAndDueDateLessThan(InvoiceStatus status, LocalDate date);

    List<Invoice> findByStatusAndDueDate(InvoiceStatus status, LocalDate date);

    @Query("SELECT i FROM Invoice i WHERE i.room.area.landlord.id = :landlordId AND i.invoicePeriod = :period")
    List<Invoice> findAllByLandlordAndPeriod(@Param("landlordId") UUID landlordId, @Param("period") LocalDate period);

    @Query("SELECT i FROM Invoice i WHERE i.room.area.id = :areaId AND i.room.area.landlord.id = :landlordId AND i.invoicePeriod = :period")
    List<Invoice> findAllByAreaAndLandlordAndPeriod(@Param("areaId") UUID areaId, @Param("landlordId") UUID landlordId, @Param("period") LocalDate period);
    void deleteAllByContractId(UUID contractId);
    List<Invoice> findByRoomAreaLandlordIdOrderByInvoicePeriodDesc(UUID landlordId);
    List<Invoice> findByContractId(UUID contractId);
    Page<Invoice> findByRoomAreaLandlordIdAndStatusOrderByInvoicePeriodDesc(UUID landlordId, InvoiceStatus status, Pageable pageable);

    Page<Invoice> findByRoomAreaLandlordIdOrderByInvoicePeriodDesc(UUID landlordId, Pageable pageable);
    Page<Invoice> findByContractTenantIdAndStatusOrderByInvoicePeriodDesc(UUID tenantId, InvoiceStatus status, Pageable pageable);

    Page<Invoice> findByContractTenantIdOrderByInvoicePeriodDesc(UUID tenantId, Pageable pageable);
    Page<Invoice> findByRoomAreaLandlordIdAndRoomAreaIdAndStatusOrderByInvoicePeriodDesc(UUID landlordId, UUID areaId, InvoiceStatus status, Pageable pageable);

    Page<Invoice> findByRoomAreaLandlordIdAndRoomAreaIdOrderByInvoicePeriodDesc(UUID landlordId, UUID areaId, Pageable pageable);
}