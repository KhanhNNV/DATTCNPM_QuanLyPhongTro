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

    //Lấy trực tiếp người đại diện (tenant) từ bảng Contract
    @Query("SELECT DISTINCT c.tenant FROM Contract c WHERE c.room.area.id = :areaId")
    List<User> findTenantsByAreaId(@Param("areaId") UUID areaId);

    @Query("SELECT COUNT(c) > 0 FROM Contract c " +
            "WHERE c.tenant.id = :tenantId " +
            "AND c.room.area.landlord.id = :landlordId")
    boolean existsTenantInLandlordAreas(@Param("tenantId") UUID tenantId,
                                        @Param("landlordId") UUID landlordId);
}