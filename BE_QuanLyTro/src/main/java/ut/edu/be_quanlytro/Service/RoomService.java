package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.RoomRequest;
import ut.edu.be_quanlytro.Dto.Response.RoomResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
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

    @Transactional
    public RoomResponse createRoom(RoomRequest request, UUID currentUserId) {

        Area area = areaRepository.findById(request.getAreaId())
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        if (!area.getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền thêm phòng vào khu trọ của người khác.");
        }

        if (roomRepository.existsByRoomNumberAndAreaId(request.getRoomNumber(), request.getAreaId())) {
            throw new BadRequestException("Phòng " + request.getRoomNumber() + " đã tồn tại trong khu trọ này");
        }

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

        Room savedRoom = roomRepository.save(newRoom);

        User userProxy = userRepository.getReferenceById(currentUserId);

        String action = "CREATE_ROOM";
        String entityName = "rooms";
        String description = String.format("Tạo mới phòng %s trong khu trọ %s",
                savedRoom.getRoomNumber(), area.getName());

        activityLog.createLog(userProxy, action, entityName, savedRoom.getId(), description);

        return mapToDTO(savedRoom);
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByArea(UUID areaId, UUID currentUserId) {

        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách phòng của khu trọ khác.");
            }
        }

        return roomRepository.findByAreaId(areaId)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public RoomResponse getRoomResponseById(UUID id, UUID currentUserId) {
        Room room = getRoomById(id);

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem thông tin phòng thuộc khu trọ của người khác.");
            }
        }

        return mapToDTO(room);
    }

    public Room getRoomById(UUID id) {
        return roomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng với ID: " + id));
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getRoomsByAreaAndStatus(UUID areaId, RoomStatus status, UUID currentUserId) {

        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Khu trọ không tồn tại"));

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem danh sách phòng của khu trọ khác.");
            }
        }

        return roomRepository.findByAreaIdAndStatus(areaId, status)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional
    public RoomResponse updateRoom(UUID id, RoomRequest request, UUID currentUserId) {
        Room existingRoom = getRoomById(id);

        if (!existingRoom.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa phòng thuộc khu trọ của người khác.");
        }

        if (request.getFloor() != null) existingRoom.setFloor(request.getFloor());
        if (request.getRoomNumber() != null) {
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

        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "UPDATE_ROOM";
        String entityName = "rooms";
        String description = String.format("Cập nhật thông tin phòng %s trong khu trọ %s",
                updatedRoom.getRoomNumber(), updatedRoom.getArea().getName());

        activityLog.createLog(userProxy, action, entityName, updatedRoom.getId(), description);

        return mapToDTO(updatedRoom);
    }

    @Transactional
    public void deleteRoom(UUID id, UUID currentUserId) {
        Room room = getRoomById(id);

        if (!room.getArea().getLandlord().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xóa phòng thuộc khu trọ của người khác.");
        }

        if (room.getStatus() == RoomStatus.RENTED) {
            throw new BadRequestException("Không thể xóa phòng đang có người thuê");
        }

        String roomNumber = room.getRoomNumber();
        String areaName = room.getArea().getName();

        roomRepository.delete(room);

        User userProxy = userRepository.getReferenceById(currentUserId);
        String action = "DELETE_ROOM";
        String entityName = "rooms";
        String description = String.format("Xóa phòng %s khỏi khu trọ %s", roomNumber, areaName);

        activityLog.createLog(userProxy, action, entityName, id, description);
    }

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