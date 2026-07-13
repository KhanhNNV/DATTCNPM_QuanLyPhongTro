package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Issue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;

public interface IssueRepository extends JpaRepository<Issue, UUID> {
    // Dành cho Khách thuê: Lấy danh sách sự cố do chính họ báo cáo
    Page<Issue> findByTenantIdOrderByCreatedAtDesc(UUID tenantId, Pageable pageable);

    // Dành cho Chủ trọ: Lấy danh sách sự cố của toàn bộ các phòng thuộc khu trọ của họ
    Page<Issue> findByRoomAreaLandlordIdOrderByCreatedAtDesc(UUID landlordId, Pageable pageable);
}