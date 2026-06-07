package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Deposit;
import ut.edu.be_quanlytro.Entity.Enum.DepositStatus;

import java.util.List;
import java.util.UUID;

@Repository
public interface DepositRepository extends JpaRepository<Deposit, UUID> {

    // 1. Lấy toàn bộ lịch sử cọc của một phòng cụ thể
    List<Deposit> findByRoomId(UUID roomId);

    // 2. Tìm phiếu cọc của một phòng theo trạng thái (VD: Tìm xem phòng này có phiếu nào đang PENDING không)
    List<Deposit> findByRoomIdAndStatus(UUID roomId, DepositStatus status);

    // 3. Kiểm tra nhanh xem phòng có đang bị cọc không (Trả về true/false)
    boolean existsByRoomIdAndStatus(UUID roomId, DepositStatus status);

    // 4. Lấy danh sách phiếu cọc theo số điện thoại (Dùng để tra cứu lịch sử cọc của một khách vãng lai)
    List<Deposit> findByPhone(String phone);

    // 5. 🌟 Lọc tất cả phiếu cọc thuộc một Khu trọ (Dùng cho chức năng xem danh sách cọc theo khu)
    @Query("SELECT d FROM Deposit d WHERE d.room.area.id = :areaId")
    List<Deposit> findByAreaId(@Param("areaId") UUID areaId);

    // 6. 🌟 Lọc tất cả phiếu cọc thuộc quyền quản lý của một Chủ trọ (Dùng cho trang Tổng quan/Dashboard)
    @Query("SELECT d FROM Deposit d WHERE d.room.area.landlord.id = :landlordId")
    List<Deposit> findByLandlordId(@Param("landlordId") UUID landlordId);

    // 7. Lọc phiếu cọc theo Chủ trọ và Trạng thái (VD: Chủ trọ muốn xem tất cả các phiếu Đang chờ xử lý)
    @Query("SELECT d FROM Deposit d WHERE d.room.area.landlord.id = :landlordId AND d.status = :status")
    List<Deposit> findByLandlordIdAndStatus(@Param("landlordId") UUID landlordId, @Param("status") DepositStatus status);
}