package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.RoomRequest;
import ut.edu.be_quanlytro.Dto.Response.RoomResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Repository.AreaRepository;
import ut.edu.be_quanlytro.Repository.RoomRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomService {

    private final RoomRepository roomRepository;
    private final AreaRepository areaRepository;
    private final ActivityLogService activityLog;
    private final UserRepository userRepository;

    // ================= CREATE =================
    @Transactional
    public Room createRoom(RoomRequest request, UUID currentUserId) {

        // 1. Kiểm tra khu trọ
        Area area = areaRepository.findById(request.getAreaId())
                .orElseThrow(() -> new RuntimeException("Khu trọ không tồn tại"));

        // 2. Kiểm tra trùng mã phòng
        if (roomRepository.existsByRoomNumberAndAreaId(request.getRoomNumber(), request.getAreaId())) {
            throw new RuntimeException("Phòng " + request.getRoomNumber() + " đã tồn tại trong khu trọ này");
        }

        // 3. Build Entity
        Room newRoom = Room.builder()
                .area(area)
                .floor(request.getFloor())
                .roomNumber(request.getRoomNumber())
                .areaSize(request.getAreaSize())
                .rentPrice(request.getRentPrice())
                .depositAmount(request.getDepositAmount())
                .maxOccupants(request.getMaxOccupants())
                .status(request.getStatus() != null ? request.getStatus() : RoomStatus.AVAILABLE)
                .build();

        // 4. LƯU PHÒNG TRƯỚC ĐỂ LẤY ID
        Room savedRoom = roomRepository.save(newRoom);

        // 5. GHI LOG
        User userProxy = userRepository.getReferenceById(currentUserId);

        String action = "CREATE_ROOM";
        String entityName = "rooms";
        String description = String.format("Tạo mới phòng %s trong khu trọ %s",
                savedRoom.getRoomNumber(), area.getName());

        activityLog.createLog(userProxy, action, entityName, savedRoom.getId(), description);

        // 6. Trả về entity đã lưu
        return savedRoom;
    }

    // ================= READ (TRẢ VỀ DTO) =================

    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByArea(UUID areaId) {
        return roomRepository.findByAreaId(areaId)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    public RoomResponse getRoomResponseById(UUID id) {
        Room room = getRoomById(id);
        return mapToDTO(room);
    }

    public Room getRoomById(UUID id) {
        return roomRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng với ID: " + id));
    }

    // Lấy danh sách phòng theo trạng thái trong 1 khu trọ cụ thể
    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByAreaAndStatus(UUID areaId, RoomStatus status) {
        return roomRepository.findByAreaIdAndStatus(areaId, status)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    // ================= UPDATE =================
    @Transactional
    public Room updateRoom(UUID id, RoomRequest request, UUID currentUserId) {
        Room existingRoom = getRoomById(id);

        // Cập nhật các trường thông tin
        if (request.getFloor() != null) existingRoom.setFloor(request.getFloor());
        if (request.getRoomNumber() != null) {
            if (!existingRoom.getRoomNumber().equals(request.getRoomNumber()) &&
                    roomRepository.existsByRoomNumberAndAreaId(request.getRoomNumber(), existingRoom.getArea().getId())) {
                throw new RuntimeException("Tên phòng này đã bị trùng");
            }
            existingRoom.setRoomNumber(request.getRoomNumber());
        }
        if (request.getAreaSize() != null) existingRoom.setAreaSize(request.getAreaSize());
        if (request.getRentPrice() != null) existingRoom.setRentPrice(request.getRentPrice());
        if (request.getDepositAmount() != null) existingRoom.setDepositAmount(request.getDepositAmount());
        if (request.getMaxOccupants() != null) existingRoom.setMaxOccupants(request.getMaxOccupants());
        if (request.getStatus() != null) existingRoom.setStatus(request.getStatus());

        Room updatedRoom = roomRepository.save(existingRoom);

        // GHI LOG UPDATE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "UPDATE_ROOM";
        String entityName = "rooms";
        String description = String.format("Cập nhật thông tin phòng %s trong khu trọ %s",
                updatedRoom.getRoomNumber(), updatedRoom.getArea().getName());

        activityLog.createLog(userProxy, action, entityName, updatedRoom.getId(), description);

        return updatedRoom;
    }

    // ================= DELETE =================
    @Transactional
    public void deleteRoom(UUID id, UUID currentUserId) {
        Room room = getRoomById(id);

        if (room.getStatus() == RoomStatus.RENTED) {
            throw new RuntimeException("Không thể xóa phòng đang có người thuê");
        }

        // Lấy thông tin phòng và khu trọ trước khi xóa để ghi log
        String roomNumber = room.getRoomNumber();
        String areaName = room.getArea().getName();

        roomRepository.delete(room);

        // GHI LOG DELETE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "DELETE_ROOM";
        String entityName = "rooms";
        String description = String.format("Xóa phòng %s khỏi khu trọ %s", roomNumber, areaName);

        activityLog.createLog(userProxy, action, entityName, id, description);
    }

    // ================= HELPER / MAPPER =================
    private RoomResponse mapToDTO(Room room) {
        if (room == null) return null;

        return RoomResponse.builder()
                .id(room.getId())
                .areaName(room.getArea() != null ? room.getArea().getName() : null)
                .floor(room.getFloor())
                .roomNumber(room.getRoomNumber())
                .areaSize(room.getAreaSize())
                .rentPrice(room.getRentPrice())
                .depositAmount(room.getDepositAmount())
                .maxOccupants(room.getMaxOccupants())
                .status(room.getStatus())
                .build();
    }
}