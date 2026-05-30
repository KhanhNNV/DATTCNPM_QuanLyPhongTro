package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.Area;

import java.util.List;
import java.util.UUID;

@Repository
public interface AreaRepository extends JpaRepository<Area, UUID> {
    // Lấy danh sách khu trọ của một chủ trọ cụ thể
    List<Area> findByLandlordId(UUID landlordId);

    // Kiểm tra tên khu trọ đã tồn tại với chủ trọ này chưa (chống trùng lặp)
    boolean existsByLandlordIdAndName(UUID landlordId, String name);
}