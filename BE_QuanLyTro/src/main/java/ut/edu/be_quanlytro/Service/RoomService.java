package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException; // Thêm import 403
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.RoomRequest;
import ut.edu.be_quanlytro.Dto.Response.RoomResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.BadRequestException; // Thêm import 400
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException; // Thêm import 404
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
    public RoomResponse createRoom(RoomRequest request, UUID currentUserId) {

        // 1. Kiểm tra khu trọ
        Area area = areaRepository.findById(request.getAreaId())
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        // 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu khu trọ
        if (!area.getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền thêm phòng vào khu trọ của người khác.");
        }

        // 2. Kiểm tra trùng mã phòng
        if (roomRepository.existsByRoomNumberAndAreaId(request.getRoomNumber(), request.getAreaId())) {
            throw new BadRequestException("Phòng " + request.getRoomNumber() + " đã tồn tại trong khu trọ này");
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

        // 6. MAP ENTITY SANG DTO VÀ TRẢ VỀ
        return mapToDTO(savedRoom);
    }

    // ================= READ (TRẢ VỀ DTO) =================
    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByArea(UUID areaId, UUID currentUserId) {

        // 1. Lấy thông tin Khu trọ để kiểm tra quyền
        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        // 2. Lấy thông tin người dùng đang gọi API
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        // 3. 🔒 KIỂM TRA BẢO MẬT: Nếu là Chủ trọ thì chỉ được xem phòng khu của mình
        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách phòng của khu trọ khác.");
            }
        }

        // 4. Nếu qua được chốt kiểm tra, lấy danh sách và map sang DTO
        return roomRepository.findByAreaId(areaId)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }


    @Transactional(readOnly = true)
    public RoomResponse getRoomResponseById(UUID id, UUID currentUserId) {
        // 1. Lấy thông tin Phòng từ Database (Dùng lại hàm helper cũ của bạn)
        Room room = getRoomById(id);

        // 2. Lấy thông tin người dùng đang gọi API
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        // 3. 🔒 KIỂM TRA BẢO MẬT: Nếu là Chủ trọ thì chỉ được xem phòng thuộc khu của mình
        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem thông tin phòng thuộc khu trọ của người khác.");
            }
        }

        // 4. Map sang DTO và trả về
        return mapToDTO(room);
    }

    public Room getRoomById(UUID id) {
        return roomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng với ID: " + id));
    }

    // ================= READ (LỌC THEO TRẠNG THÁI) =================
    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByAreaAndStatus(UUID areaId, RoomStatus status, UUID currentUserId) {

        // 1. Lấy thông tin Khu trọ để kiểm tra quyền
        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        // 2. Lấy thông tin người dùng đang gọi API
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        // 3. 🔒 KIỂM TRA BẢO MẬT: Nếu là Chủ trọ thì chỉ được xem phòng khu của mình
        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách phòng của khu trọ khác.");
            }
        }

        // 4. Nếu qua được chốt kiểm tra, lấy danh sách theo trạng thái và map sang DTO
        return roomRepository.findByAreaIdAndStatus(areaId, status)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }
    // ================= UPDATE =================
    @Transactional
    public RoomResponse updateRoom(UUID id, RoomRequest request, UUID currentUserId) {
        Room existingRoom = getRoomById(id);

        // 1. 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu
        // Từ phòng -> Gọi lên Khu trọ -> Gọi lên Chủ trọ -> Lấy ID đem so sánh
        if (!existingRoom.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa phòng thuộc khu trọ của người khác.");
        }

        // 2. Cập nhật các trường thông tin nếu có truyền lên
        if (request.getFloor() != null) existingRoom.setFloor(request.getFloor());
        if (request.getRoomNumber() != null) {
            // Chỉ kiểm tra trùng lặp nếu người dùng thực sự đổi tên phòng
            if (!existingRoom.getRoomNumber().equals(request.getRoomNumber()) &&
                    roomRepository.existsByRoomNumberAndAreaId(request.getRoomNumber(), existingRoom.getArea().getId())) {
                throw new BadRequestException("Tên phòng này đã bị trùng trong khu trọ");
            }
            existingRoom.setRoomNumber(request.getRoomNumber());
        }
        if (request.getAreaSize() != null) existingRoom.setAreaSize(request.getAreaSize());
        if (request.getRentPrice() != null) existingRoom.setRentPrice(request.getRentPrice());
        if (request.getDepositAmount() != null) existingRoom.setDepositAmount(request.getDepositAmount());
        if (request.getMaxOccupants() != null) existingRoom.setMaxOccupants(request.getMaxOccupants());
        if (request.getStatus() != null) existingRoom.setStatus(request.getStatus());

        Room updatedRoom = roomRepository.save(existingRoom);

        // 3. GHI LOG UPDATE
        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "UPDATE_ROOM";
        String entityName = "rooms";
        String description = String.format("Cập nhật thông tin phòng %s trong khu trọ %s",
                updatedRoom.getRoomNumber(), updatedRoom.getArea().getName());

        activityLog.createLog(userProxy, action, entityName, updatedRoom.getId(), description);

        // 4. MAP SANG DTO VÀ TRẢ VỀ
        return mapToDTO(updatedRoom);
    }

    // ================= DELETE =================
    @Transactional
    public void deleteRoom(UUID id, UUID currentUserId) {
        Room room = getRoomById(id);

        // 1. 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu
        // Từ phòng -> Gọi lên Khu trọ -> Gọi lên Chủ trọ -> Lấy ID đem so sánh
        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xóa phòng thuộc khu trọ của người khác.");
        }

        // 2. Kiểm tra điều kiện nghiệp vụ: Không cho xóa phòng đang có khách
        if (room.getStatus() == RoomStatus.RENTED) {
            throw new BadRequestException("Không thể xóa phòng đang có người thuê");
        }

        // 3. Lấy thông tin phòng và khu trọ trước khi xóa để ghi log
        String roomNumber = room.getRoomNumber();
        String areaName = room.getArea().getName();

        // 4. Xóa phòng
        roomRepository.delete(room);

        // 5. GHI LOG DELETE
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