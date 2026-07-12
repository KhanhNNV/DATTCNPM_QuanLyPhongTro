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

    // UC27: Tìm các hóa đơn chưa khớp tiền mà ngày hạn chót nhỏ hơn ngày hôm nay
    List<Invoice> findByStatusAndDueDateLessThan(InvoiceStatus status, LocalDate date);

    // UC26: Tìm các hóa đơn chưa đóng tiền mà sắp đến hạn (Ví dụ: còn đúng 1 ngày hoặc chính là ngày hôm nay)
    List<Invoice> findByStatusAndDueDate(InvoiceStatus status, LocalDate date);

    // 1. Tìm tất cả hóa đơn trong tháng của TẤT CẢ các khu trọ thuộc chủ trọ này
    @Query("SELECT i FROM Invoice i WHERE i.room.area.landlord.id = :landlordId AND i.invoicePeriod = :period")
    List<Invoice> findAllByLandlordAndPeriod(@Param("landlordId") UUID landlordId, @Param("period") LocalDate period);

    // 2. Tìm tất cả hóa đơn trong tháng của MỘT KHU TRỌ cụ thể thuộc chủ trọ này (để lọc nâng cao)
    @Query("SELECT i FROM Invoice i WHERE i.room.area.id = :areaId AND i.room.area.landlord.id = :landlordId AND i.invoicePeriod = :period")
    List<Invoice> findAllByAreaAndLandlordAndPeriod(@Param("areaId") UUID areaId, @Param("landlordId") UUID landlordId, @Param("period") LocalDate period);
    void deleteAllByContractId(UUID contractId);
    // Sắp xếp theo kỳ hóa đơn mới nhất giảm dần
    List<Invoice> findByRoomAreaLandlordIdOrderByInvoicePeriodDesc(UUID landlordId);

    List<Invoice> findByContractId(UUID contractId);
    // 1. Dùng khi Frontend CÓ TRUYỀN trạng thái (vd: ?status=UNPAID)
    Page<Invoice> findByRoomAreaLandlordIdAndStatusOrderByInvoicePeriodDesc(UUID landlordId, InvoiceStatus status, Pageable pageable);

    // 2. Dùng khi Frontend KHÔNG TRUYỀN trạng thái (lấy tất cả)
    Page<Invoice> findByRoomAreaLandlordIdOrderByInvoicePeriodDesc(UUID landlordId, Pageable pageable);
}