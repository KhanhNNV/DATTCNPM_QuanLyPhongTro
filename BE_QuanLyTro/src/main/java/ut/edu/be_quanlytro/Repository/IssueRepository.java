package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.Enum.IssueStatus;
import ut.edu.be_quanlytro.Entity.Issue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.UUID;

public interface IssueRepository extends JpaRepository<Issue, UUID> {


    Page<Issue> findByTenantIdOrderByCreatedAtDesc(UUID tenantId, Pageable pageable);

    Page<Issue> findByTenantIdAndStatusOrderByCreatedAtDesc(UUID tenantId, IssueStatus status, Pageable pageable);

    Page<Issue> findByRoomAreaLandlordIdOrderByCreatedAtDesc(UUID landlordId, Pageable pageable);

    Page<Issue> findByRoomAreaLandlordIdAndStatusOrderByCreatedAtDesc(UUID landlordId, IssueStatus status, Pageable pageable);

    Page<Issue> findByRoomAreaLandlordIdAndRoomIdOrderByCreatedAtDesc(UUID landlordId, UUID roomId, Pageable pageable);

    Page<Issue> findByRoomAreaLandlordIdAndRoomIdAndStatusOrderByCreatedAtDesc(UUID landlordId, UUID roomId, IssueStatus status, Pageable pageable);

    Page<Issue> findByRoomAreaLandlordIdAndRoomAreaIdAndStatusOrderByCreatedAtDesc(UUID landlordId, UUID areaId, IssueStatus status, Pageable pageable);

    Page<Issue> findByRoomAreaLandlordIdAndRoomAreaIdOrderByCreatedAtDesc(UUID landlordId, UUID areaId, Pageable pageable);
}