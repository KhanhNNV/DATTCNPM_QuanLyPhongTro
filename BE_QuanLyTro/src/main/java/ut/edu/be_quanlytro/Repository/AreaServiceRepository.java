package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.AreaService;

import java.util.List;
import java.util.UUID;

@Repository
public interface AreaServiceRepository extends JpaRepository<AreaService, UUID> {

    List<AreaService> findByAreaId(UUID areaId);

    List<AreaService> findByAreaIdAndIsActiveTrue(UUID areaId);

    boolean existsByAreaIdAndName(UUID areaId, String name);
}