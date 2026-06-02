package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    // Dùng JPQL để tìm tất cả Khách thuê (User) dựa vào hợp đồng của họ tại Khu trọ (Area)
    @Query("SELECT DISTINCT cm.user FROM ContractMember cm WHERE cm.contract.room.area.id = :areaId")
    List<User> findTenantsByAreaId(@Param("areaId") UUID areaId);

}