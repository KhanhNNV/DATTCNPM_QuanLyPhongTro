    package ut.edu.be_quanlytro.Repository;

    import org.springframework.data.jpa.repository.JpaRepository;
    import org.springframework.stereotype.Repository;
    import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
    import ut.edu.be_quanlytro.Entity.Room;

    import java.util.List;
    import java.util.UUID;

    @Repository
    public interface RoomRepository extends JpaRepository<Room, UUID> {

        List<Room> findByAreaId(UUID areaId);
        boolean existsByRoomNumberAndAreaId(String roomNumber, UUID areaId);
        List<Room> findByAreaIdAndStatus(UUID areaId, RoomStatus status);
    }