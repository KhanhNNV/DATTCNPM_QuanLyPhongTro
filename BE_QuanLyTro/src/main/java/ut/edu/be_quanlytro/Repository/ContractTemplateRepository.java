package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ut.edu.be_quanlytro.Entity.ContractTemplate;

import java.util.List;
import java.util.UUID;

public interface ContractTemplateRepository extends JpaRepository<ContractTemplate, UUID> {

    // 1. Lấy danh sách mẫu (Bao gồm mẫu Hệ thống + Mẫu của Chủ trọ) và đang Active
    @Query("SELECT t FROM ContractTemplate t WHERE (t.landlord IS NULL OR t.landlord.id = :landlordId) AND t.isActive = true ORDER BY t.createdAt DESC")
    List<ContractTemplate> findAvailableTemplatesForLandlord(@Param("landlordId") UUID landlordId);

    // 2. Tìm một mẫu cụ thể đang Active
    @Query("SELECT t FROM ContractTemplate t WHERE t.id = :id AND t.isActive = true")
    ContractTemplate findActiveById(@Param("id") UUID id);
}