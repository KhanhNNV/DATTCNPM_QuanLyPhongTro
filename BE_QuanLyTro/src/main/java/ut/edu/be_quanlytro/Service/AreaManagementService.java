package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.AreaRequest;
import ut.edu.be_quanlytro.Dto.Request.OnboardingRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.Enum.RoomStatus;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
import ut.edu.be_quanlytro.Repository.*;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AreaManagementService {

    private final AreaRepository areaRepository;
    private final UserRepository userRepository;
    private final ActivityLogService activityLog;
    private final AreaServiceRepository areaServiceRepository;
    private final RoomRepository roomRepository;
    private final ContractRepository contractRepository;

    @Transactional
    public AreaResponse onboardNewLandlord(OnboardingRequest request, UUID landlordId) {

        User landlord = userRepository.findById(landlordId)
                .orElseThrow(() -> new ResourceNotFoundException("Chủ trọ không tồn tại"));

        if(landlord.getRole() != RoleType.LANDLORD) {
            throw new AccessDeniedException("Bạn không có quyền thực hiện chức năng này vì không phải là chủ trọ");
        }
        if (request.getBankId() != null && !request.getBankId().trim().isEmpty()) {
            landlord.setBankId(request.getBankId());
            landlord.setAccountNo(request.getAccountNo());
            landlord.setAccountName(request.getAccountName());

            userRepository.save(landlord);
        }

        Area newArea = Area.builder()
                .landlord(landlord)
                .name(request.getName())
                .address(request.getAddress())
                .invoiceDay(request.getInvoiceDay())
                .dueDate(request.getDueDate())
                .build();
        Area savedArea = areaRepository.save(newArea);

        if (request.getServices() != null && !request.getServices().isEmpty()) {
            List<AreaService> areaServices = request.getServices().stream().map(svc ->
                    AreaService.builder()
                            .area(savedArea)
                            .name(svc.getName())
                            .calcType(svc.getCalcType())
                            .price(svc.getPrice())
                            .isActive(true)
                            .build()
            ).toList();

            areaServiceRepository.saveAll(areaServices);
        }

        List<Room> newRooms = new ArrayList<>();
        List<Integer> floors = request.getRoomsPerFloor();

        if (floors != null && !floors.isEmpty()) {
            int globalRoomCounter = 1;

            for (int i = 0; i < floors.size(); i++) {
                int floorNumber = i + 1;
                int numberOfRooms = floors.get(i);

                for (int j = 1; j <= numberOfRooms; j++) {
                    String roomSequence = String.format("%03d", globalRoomCounter);

                    Room room = Room.builder()
                            .area(savedArea)
                            .floor(floorNumber)
                            .roomNumber(roomSequence)
                            .areaSize(request.getDefaultAreaSize())
                            .rentPrice(request.getDefaultRentPrice())
                            .depositAmount(request.getDefaultDepositAmount())
                            .maxOccupants(request.getDefaultMaxOccupants())
                            .status(RoomStatus.AVAILABLE)
                            .build();

                    newRooms.add(room);
                    globalRoomCounter++;
                }
            }
            roomRepository.saveAll(newRooms);
        }

        String description = String.format("Hoàn tất thiết lập ban đầu: Tạo khu %s, %d dịch vụ và %d phòng",
                savedArea.getName(),
                request.getServices() != null ? request.getServices().size() : 0,
                newRooms.size());

        activityLog.createLog(landlord, "ONBOARDING_COMPLETED", "areas, rooms, area_services", savedArea.getId(), description);

        return mapToResponse(savedArea);
    }

    public List<AreaResponse> getAreasByLandlord(UUID landlordId) {
        return areaRepository.findByLandlordId(landlordId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    public AreaResponse getAreaById(UUID id, UUID currentUserId) {
        Area area = getAreaEntityById(id);

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem khu trọ của người khác.");
            }
        }
        else if (currentUser.getRole() == RoleType.TENANT) {
            boolean hasAccessToArea = contractRepository.existsByTenantIdAndRoom_Area_Id(currentUserId, id);

            if (!hasAccessToArea) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có hợp đồng thuê nào tại khu trọ này.");
            }
        }

        return mapToResponse(area);
    }

    public Area getAreaEntityById(UUID id) {
        return areaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khu trọ"));
    }

    @Transactional
    public AreaResponse updateArea(UUID id, AreaRequest request, UUID landlordId) {
        Area area = getAreaEntityById(id);

        if (!area.getLandlord().getId().equals(landlordId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa khu trọ của người khác.");
        }

        if (request.getName() != null) area.setName(request.getName());
        if (request.getAddress() != null) area.setAddress(request.getAddress());
        if (request.getInvoiceDay() != null) area.setInvoiceDay(request.getInvoiceDay());
        if (request.getDueDate() != null) area.setDueDate(request.getDueDate());

        Area updatedArea = areaRepository.save(area);

        User landlord = userRepository.getReferenceById(landlordId);
        activityLog.createLog(landlord, "UPDATE_AREA", "areas", updatedArea.getId(), "Cập nhật thông tin khu trọ: " + updatedArea.getName());

        return mapToResponse(updatedArea);
    }

    @Transactional
    public void deleteArea(UUID id, UUID landlordId) {
        Area area = getAreaEntityById(id);

        if (!area.getLandlord().getId().equals(landlordId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xóa khu trọ của người khác.");
        }

        List<Room> rooms = roomRepository.findByAreaId(id);
        if (!rooms.isEmpty()) {
            roomRepository.deleteAll(rooms);
        }

        List<AreaService> services = areaServiceRepository.findByAreaId(id);
        if (!services.isEmpty()) {
            areaServiceRepository.deleteAll(services);
        }

        areaRepository.delete(area);

        User landlord = userRepository.getReferenceById(landlordId);
        activityLog.createLog(landlord, "DELETE_AREA", "areas", id, "Xóa khu trọ: " + area.getName());
    }

    private AreaResponse mapToResponse(Area area) {
        return AreaResponse.builder()
                .id(area.getId())
                .name(area.getName())
                .address(area.getAddress())
                .invoiceDay(area.getInvoiceDay())
                .dueDate(area.getDueDate())
                .createdAt(area.getCreatedAt())
                .build();
    }
}