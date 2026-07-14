package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContractRepository extends JpaRepository<Contract, UUID> {

    Optional<Contract> findByTenantIdAndStatus(UUID tenantId, ContractStatus status);

    List<Contract> findByRoomId(UUID roomId);

    long countByTenantIdAndStatusIn(UUID tenantId, List<ContractStatus> statuses);

    Optional<Contract> findFirstByTenantIdAndStatusInOrderByCreatedAtDesc(UUID tenantId, List<ContractStatus> statuses);

    long countByTenantId(UUID tenantId);

    List<Contract> findByStatusAndEndDateBefore(ContractStatus status, LocalDate date);

    boolean existsByTemplateId(UUID templateId);

    List<Contract> findByRoomAreaIdAndStatus(UUID areaId, ContractStatus status);

    boolean existsByTenantIdAndRoom_Area_Id(UUID tenantId, UUID areaId);

    List<Contract> findByRoomAreaIdAndRoomAreaLandlordIdOrderByCreatedAtDesc(UUID areaId, UUID landlordId);
}