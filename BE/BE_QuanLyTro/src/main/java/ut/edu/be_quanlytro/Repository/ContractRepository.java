package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.Enum.ContractStatus;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContractRepository extends JpaRepository<Contract, UUID> {

    // Tìm hợp đồng đang có hiệu lực (SIGNED) của khách thuê để lấy ID phòng và khu trọ
    Optional<Contract> findByTenantIdAndStatus(UUID tenantId, ContractStatus status);
}