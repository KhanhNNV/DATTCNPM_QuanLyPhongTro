    package ut.edu.be_quanlytro.Repository;

    import org.springframework.data.jpa.repository.JpaRepository;
    import org.springframework.stereotype.Repository;
    import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
    import ut.edu.be_quanlytro.Entity.Room;

    import java.util.List;
    import java.util.UUID;

    @Repository
    public interface RoomRepository extends JpaRepository<Room, UUID> {

        // Tìm tất cả các phòng thuộc về một khu trọ cụ thể
        List<Room> findByAreaId(UUID areaId);

        // Kiểm tra xem mã phòng đã tồn tại trong khu trọ này chưa (tránh tạo trùng VD: 2 phòng 101)
        boolean existsByRoomNumberAndAreaId(String roomNumber, UUID areaId);

        List<Room> findByAreaIdAndStatus(UUID areaId, RoomStatus status);
    }