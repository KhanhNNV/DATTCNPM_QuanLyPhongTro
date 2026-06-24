package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContractRepository extends JpaRepository<Contract, UUID> {

    // Tìm hợp đồng đang có hiệu lực (SIGNED) của khách thuê để lấy ID phòng và khu trọ
    Optional<Contract> findByTenantIdAndStatus(UUID tenantId, ContractStatus status);

    // Tìm toàn bộ hợp đồng của một phòng
    List<Contract> findByRoomId(UUID roomId);

    // Tìm tất cả hợp đồng thuộc các phòng (Room) nằm trong khu trọ (Area) của Chủ trọ (Landlord) này
    // Sắp xếp theo ngày tạo mới nhất (giảm dần)
    List<Contract> findByRoomAreaLandlordIdOrderByCreatedAtDesc(UUID landlordId);

    // Tìm hợp đồng mới nhất của khách thuê thuộc 1 trong các trạng thái truyền vào (DRAFT, ACTIVE)
    Optional<Contract> findFirstByTenantIdAndStatusInOrderByCreatedAtDesc(UUID tenantId, List<ContractStatus> statuses);

    long countByTenantId(UUID tenantId);

    // Tìm các hợp đồng đang CÓ HIỆU LỰC (SIGNED) nhưng ngày kết thúc (endDate) đã nhỏ hơn ngày hôm nay
    List<Contract> findByStatusAndEndDateBefore(ContractStatus status, LocalDate date);

    boolean existsByTemplateId(UUID templateId);
    // Tìm tất cả hợp đồng đang hoạt động của một khu trọ cụ thể
    List<Contract> findByRoomAreaIdAndStatus(UUID areaId, ContractStatus status);
}