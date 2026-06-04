package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.AreaServiceRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaServiceResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.User;
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

    // ================= CREATE =================
    @Transactional

    public AreaServiceResponse createService(UUID areaId, AreaServiceRequest request, UUID landlordId) {
        Area area = areaManagementService.getAreaEntityById(areaId);

        if (areaServiceRepository.existsByAreaIdAndName(areaId, request.getName())) {
            throw new RuntimeException("Dịch vụ này đã tồn tại trong khu trọ");
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

    // ================= READ =================
    public List<AreaServiceResponse> getServicesByAreaId(UUID areaId) {
        return areaServiceRepository.findByAreaId(areaId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ================= UPDATE =================
    @Transactional
    // THÊM: Tham số UUID landlordId
    public AreaServiceResponse updateService(UUID serviceId, AreaServiceRequest request, UUID landlordId) {
        AreaService service = areaServiceRepository.findById(serviceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ"));

        if (request.getName() != null) service.setName(request.getName());
        if (request.getCalcType() != null) service.setCalcType(request.getCalcType());
        if (request.getPrice() != null) service.setPrice(request.getPrice());

        AreaService updatedService = areaServiceRepository.save(service);


        User landlord = userRepository.getReferenceById(landlordId);
        String description = String.format("Cập nhật thông tin dịch vụ '%s'", updatedService.getName());
        activityLog.createLog(landlord, "UPDATE_AREA_SERVICE", "area_services", updatedService.getId(), description);

        return mapToResponse(updatedService);
    }

    // MAPPER
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