package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Enum.IssueStatus;
import ut.edu.be_quanlytro.Entity.Issue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;

public interface IssueRepository extends JpaRepository<Issue, UUID> {

    //  Không lọc
    Page<Issue> findByTenantIdOrderByCreatedAtDesc(UUID tenantId, Pageable pageable);
    //  Có lọc status
    Page<Issue> findByTenantIdAndStatusOrderByCreatedAtDesc(UUID tenantId, IssueStatus status, Pageable pageable);


    //  Không lọc
    Page<Issue> findByRoomAreaLandlordIdOrderByCreatedAtDesc(UUID landlordId, Pageable pageable);
    //  Có lọc status
    Page<Issue> findByRoomAreaLandlordIdAndStatusOrderByCreatedAtDesc(UUID landlordId, IssueStatus status, Pageable pageable);


    //  Có lọc theo phòng (Nhưng KHÔNG lọc status)
    Page<Issue> findByRoomAreaLandlordIdAndRoomIdOrderByCreatedAtDesc(UUID landlordId, UUID roomId, Pageable pageable);

    //  Có lọc theo phòng (VÀ có lọc luôn status)
    Page<Issue> findByRoomAreaLandlordIdAndRoomIdAndStatusOrderByCreatedAtDesc(UUID landlordId, UUID roomId, IssueStatus status, Pageable pageable);
    //  Có lọc theo Khu trọ VÀ Trạng thái
    Page<Issue> findByRoomAreaLandlordIdAndRoomAreaIdAndStatusOrderByCreatedAtDesc(UUID landlordId, UUID areaId, IssueStatus status, Pageable pageable);

    //  Có lọc theo Khu trọ (nhưng KHÔNG lọc trạng thái)
    Page<Issue> findByRoomAreaLandlordIdAndRoomAreaIdOrderByCreatedAtDesc(UUID landlordId, UUID areaId, Pageable pageable);
}