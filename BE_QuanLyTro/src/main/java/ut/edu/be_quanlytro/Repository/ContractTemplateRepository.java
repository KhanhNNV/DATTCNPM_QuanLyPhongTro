package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ut.edu.be_quanlytro.Entity.ContractTemplate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ContractTemplateRepository extends JpaRepository<ContractTemplate, UUID> {

    List<ContractTemplate> findByLandlordIdOrderByCreatedAtDesc(UUID landlordId);

    Optional<ContractTemplate> findByLandlordIdAndIsActiveTrue(UUID landlordId);

    Optional<ContractTemplate> findByIdAndLandlordId(UUID id, UUID landlordId);

}