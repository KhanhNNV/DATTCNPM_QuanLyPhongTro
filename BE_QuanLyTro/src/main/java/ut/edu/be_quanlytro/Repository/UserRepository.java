package ut.edu.be_quanlytro.Repository;

import ut.edu.be_quanlytro.Entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByPhone(String phone);
    boolean existsByPhone(String phone);

    List<User> findByAreaId(UUID areaId);

}