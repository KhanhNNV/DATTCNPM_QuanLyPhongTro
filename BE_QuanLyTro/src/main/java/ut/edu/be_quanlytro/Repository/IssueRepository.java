package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Enum.IssueStatus;
import ut.edu.be_quanlytro.Entity.Issue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;

public interface IssueRepository extends JpaRepository<Issue, UUID> {
    // ================= DÀNH CHO KHÁCH THUÊ =================
    // 1. Không lọc
    Page<Issue> findByTenantIdOrderByCreatedAtDesc(UUID tenantId, Pageable pageable);
    // 2. Có lọc status
    Page<Issue> findByTenantIdAndStatusOrderByCreatedAtDesc(UUID tenantId, IssueStatus status, Pageable pageable);

    // ================= DÀNH CHO CHỦ TRỌ =================
    // 1. Không lọc
    Page<Issue> findByRoomAreaLandlordIdOrderByCreatedAtDesc(UUID landlordId, Pageable pageable);
    // 2. Có lọc status
    Page<Issue> findByRoomAreaLandlordIdAndStatusOrderByCreatedAtDesc(UUID landlordId, IssueStatus status, Pageable pageable);
    // ================= DÀNH CHO CHỦ TRỌ (CẬP NHẬT THÊM LỌC THEO PHÒNG) =================

    // 3. Có lọc theo phòng (Nhưng KHÔNG lọc status)
    Page<Issue> findByRoomAreaLandlordIdAndRoomIdOrderByCreatedAtDesc(UUID landlordId, UUID roomId, Pageable pageable);

    // 4. Có lọc theo phòng (VÀ có lọc luôn status)
    Page<Issue> findByRoomAreaLandlordIdAndRoomIdAndStatusOrderByCreatedAtDesc(UUID landlordId, UUID roomId, IssueStatus status, Pageable pageable);
}