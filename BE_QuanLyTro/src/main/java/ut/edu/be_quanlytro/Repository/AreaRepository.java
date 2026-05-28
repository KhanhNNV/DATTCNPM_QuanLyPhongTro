package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Area;

import java.util.UUID;

@Repository
public interface AreaRepository extends JpaRepository<Area, UUID> {

}