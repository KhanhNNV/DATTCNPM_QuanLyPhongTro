package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.AreaServiceRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaServiceResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
import ut.edu.be_quanlytro.Entity.User;
import ut.edu.be_quanlytro.Exception.BadRequestException;
import ut.edu.be_quanlytro.Exception.ResourceNotFoundException;
import ut.edu.be_quanlytro.Repository.AreaServiceRepository;
import ut.edu.be_quanlytro.Repository.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AreaServiceManagement {

    private final AreaServiceRepository areaServiceRepository;
    private final AreaManagementService areaManagementService;
    private final ActivityLogService activityLog;
    private final UserRepository userRepository;

    @Transactional
    public AreaServiceResponse createService(UUID areaId, AreaServiceRequest request, UUID landlordId) {
        Area area = areaManagementService.getAreaEntityById(areaId);

        if (!area.getLandlord().getId().equals(landlordId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền thêm dịch vụ cho khu trọ của người khác.");
        }

        if (areaServiceRepository.existsByAreaIdAndName(areaId, request.getName())) {
            throw new BadRequestException("Dịch vụ này đã tồn tại trong khu trọ");
        }

        AreaService newService = AreaService.builder()
                .area(area)
                .name(request.getName())
                .calcType(request.getCalcType())
                .price(request.getPrice())
                .isActive(true)
                .build();

        AreaService savedService = areaServiceRepository.save(newService);

        User landlord = userRepository.getReferenceById(landlordId);
        String description = String.format("Thêm dịch vụ mới '%s' cho khu trọ '%s'", savedService.getName(), area.getName());
        activityLog.createLog(landlord, "CREATE_AREA_SERVICE", "area_services", savedService.getId(), description);

        return mapToResponse(savedService);
    }

    public List<AreaServiceResponse> getServicesByAreaId(UUID areaId, UUID currentUserId) {
        Area area = areaManagementService.getAreaEntityById(areaId);

        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại trong hệ thống"));

        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền xem dịch vụ của khu trọ khác.");
            }
        }

        return areaServiceRepository.findByAreaId(areaId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional
    public AreaServiceResponse updateService(UUID serviceId, AreaServiceRequest request, UUID landlordId) {
        AreaService service = areaServiceRepository.findById(serviceId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ"));

        if (!service.getArea().getLandlord().getId().equals(landlordId)) {
            throw new AccessDeniedException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa dịch vụ thuộc khu trọ của người khác.");
        }

        if (request.getName() != null) service.setName(request.getName());
        if (request.getCalcType() != null) service.setCalcType(request.getCalcType());
        if (request.getPrice() != null) service.setPrice(request.getPrice());

        AreaService updatedService = areaServiceRepository.save(service);

        User landlord = userRepository.getReferenceById(landlordId);
        String description = String.format("Cập nhật thông tin dịch vụ '%s' tại khu '%s'",
                updatedService.getName(), service.getArea().getName());
        activityLog.createLog(landlord, "UPDATE_AREA_SERVICE", "area_services", updatedService.getId(), description);

        return mapToResponse(updatedService);
    }

    private AreaServiceResponse mapToResponse(AreaService service) {
        return AreaServiceResponse.builder()
                .id(service.getId())
                .name(service.getName())
                .calcType(service.getCalcType())
                .price(service.getPrice())
                .isActive(service.getIsActive())
                .build();
    }
}