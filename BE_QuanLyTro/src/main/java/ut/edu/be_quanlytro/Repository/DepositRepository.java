package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Deposit;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DepositRepository extends JpaRepository<Deposit, UUID> {


    // 5. 🌟 Lọc tất cả phiếu cọc thuộc một Khu trọ (Dùng cho chức năng xem danh sách cọc theo khu)
    @Query("SELECT d FROM Deposit d WHERE d.room.area.id = :areaId")
    List<Deposit> findByAreaId(@Param("areaId") UUID areaId);

    // 6. 🌟 Lọc tất cả phiếu cọc thuộc quyền quản lý của một Chủ trọ (Dùng cho trang Tổng quan/Dashboard)
    @Query("SELECT d FROM Deposit d WHERE d.room.area.landlord.id = :landlordId")
    List<Deposit> findByLandlordId(@Param("landlordId") UUID landlordId);

    // 7. Lọc phiếu cọc theo Chủ trọ và Trạng thái (VD: Chủ trọ muốn xem tất cả các phiếu Đang chờ xử lý)
    @Query("SELECT d FROM Deposit d WHERE d.room.area.landlord.id = :landlordId AND d.status = :status")
    List<Deposit> findByLandlordIdAndStatus(@Param("landlordId") UUID landlordId, @Param("status") DepositStatus status);

    // 🌟 BỔ SUNG HÀM NÀY: Tìm danh sách phiếu cọc quá hạn
    List<Deposit> findAllByStatusAndExpectedMoveInDateBefore(DepositStatus status, LocalDate date);

    Optional<Deposit> findByContractId(UUID contractId);

}