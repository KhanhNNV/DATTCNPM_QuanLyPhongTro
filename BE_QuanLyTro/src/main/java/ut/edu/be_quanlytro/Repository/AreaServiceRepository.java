package ut.edu.be_quanlytro.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ut.edu.be_quanlytro.Entity.AreaService;

import java.util.List;
import java.util.UUID;

@Repository
public interface AreaServiceRepository extends JpaRepository<AreaService, UUID> {

    /**
     * Lấy toàn bộ danh sách dịch vụ của một khu trọ cụ thể
     * (Dùng cho màn hình quản lý dịch vụ của Chủ trọ)
     */
    List<AreaService> findByAreaId(UUID areaId);

    /**
     * Lấy danh sách các dịch vụ ĐANG HOẠT ĐỘNG của một khu trọ
     * (Rất quan trọng khi tạo Hợp đồng mới hoặc xuất Hóa đơn, chỉ load những dịch vụ đang dùng)
     */
    List<AreaService> findByAreaIdAndIsActiveTrue(UUID areaId);

    /**
     * Kiểm tra xem một dịch vụ (ví dụ: "Điện") đã tồn tại trong khu trọ này chưa
     * (Dùng ở hàm Create để chặn lỗi chủ trọ tạo 2 dịch vụ trùng tên trong cùng 1 khu)
     */
    boolean existsByAreaIdAndName(UUID areaId, String name);
}