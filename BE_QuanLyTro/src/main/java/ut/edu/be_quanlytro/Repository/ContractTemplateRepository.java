package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ut.edu.be_quanlytro.Entity.ContractTemplate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ContractTemplateRepository extends JpaRepository<ContractTemplate, UUID> {

    // 1. Lấy TẤT CẢ mẫu của một Chủ trọ (Không quan tâm true/false)
    List<ContractTemplate> findByLandlordIdOrderByCreatedAtDesc(UUID landlordId);

    // 2. Tìm MẪU MẶC ĐỊNH (isActive = true) của Chủ trọ
    Optional<ContractTemplate> findByLandlordIdAndIsActiveTrue(UUID landlordId);

    // 3. Tìm 1 mẫu cụ thể của Chủ trọ (Bảo mật 2 lớp)
    Optional<ContractTemplate> findByIdAndLandlordId(UUID id, UUID landlordId);


}