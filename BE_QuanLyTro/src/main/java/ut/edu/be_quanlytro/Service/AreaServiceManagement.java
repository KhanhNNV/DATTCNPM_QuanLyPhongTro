package ut.edu.be_quanlytro.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ut.edu.be_quanlytro.Dto.Request.AreaServiceRequest;
import ut.edu.be_quanlytro.Dto.Response.AreaServiceResponse;
import ut.edu.be_quanlytro.Entity.Area;
import ut.edu.be_quanlytro.Entity.AreaService;
import ut.edu.be_quanlytro.Entity.Enum.RoleType;
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
        // 1. Lấy thông tin Khu trọ
        Area area = areaManagementService.getAreaEntityById(areaId);

        // 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu khu trọ
        if (!area.getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền thêm dịch vụ cho khu trọ của người khác.");
        }

        // 2. Kiểm tra xem dịch vụ đã tồn tại chưa
        if (areaServiceRepository.existsByAreaIdAndName(areaId, request.getName())) {
            throw new RuntimeException("Dịch vụ này đã tồn tại trong khu trọ");
        }

        // 3. Khởi tạo và lưu dịch vụ mới
        AreaService newService = AreaService.builder()
                .area(area)
                .name(request.getName())
                .calcType(request.getCalcType())
                .price(request.getPrice())
                .isActive(true)
                .build();

        AreaService savedService = areaServiceRepository.save(newService);

        // 4. Ghi Log hoạt động
        User landlord = userRepository.getReferenceById(landlordId);
        String description = String.format("Thêm dịch vụ mới '%s' cho khu trọ '%s'", savedService.getName(), area.getName());
        activityLog.createLog(landlord, "CREATE_AREA_SERVICE", "area_services", savedService.getId(), description);

        // 5. Map sang DTO và trả về
        return mapToResponse(savedService);
    }

    // ================= READ =================
    public List<AreaServiceResponse> getServicesByAreaId(UUID areaId, UUID currentUserId) {
        // 1. Lấy thông tin Khu trọ để kiểm tra quyền
        Area area = areaManagementService.getAreaEntityById(areaId);

        // 2. Lấy thông tin người dùng đang gọi API
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại trong hệ thống"));

        // 3. 🔒 KIỂM TRA BẢO MẬT: Nếu là Chủ trọ thì chỉ được xem dịch vụ khu của mình
        if (currentUser.getRole() == RoleType.LANDLORD) {
            if (!area.getLandlord().getId().equals(currentUserId)) {
                throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền xem dịch vụ của khu trọ khác.");
            }
        }

        // 4. Nếu qua được vòng kiểm tra, lấy danh sách và map sang DTO
        return areaServiceRepository.findByAreaId(areaId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ================= UPDATE =================
    @Transactional
    // THÊM: Tham số UUID landlordId
    public AreaServiceResponse updateService(UUID serviceId, AreaServiceRequest request, UUID landlordId) {
        // 1. Lấy thông tin Dịch vụ từ Database
        AreaService service = areaServiceRepository.findById(serviceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ"));

        // 2. 🔒 KIỂM TRA BẢO MẬT: Xác nhận quyền sở hữu
        // Từ dịch vụ -> Gọi lên Khu trọ -> Gọi lên Chủ trọ -> Lấy ID đem so sánh
        if (!service.getArea().getLandlord().getId().equals(landlordId)) {
            throw new RuntimeException("Truy cập bị từ chối! Bạn không có quyền chỉnh sửa dịch vụ thuộc khu trọ của người khác.");
        }

        // 3. Cập nhật các trường thông tin nếu có truyền lên
        if (request.getName() != null) service.setName(request.getName());
        if (request.getCalcType() != null) service.setCalcType(request.getCalcType());
        if (request.getPrice() != null) service.setPrice(request.getPrice());

        AreaService updatedService = areaServiceRepository.save(service);

        // 4. Ghi Log hoạt động
        User landlord = userRepository.getReferenceById(landlordId);
        // Tối ưu: Thêm tên Khu trọ vào Log để dễ theo dõi dịch vụ này thuộc khu nào
        String description = String.format("Cập nhật thông tin dịch vụ '%s' tại khu '%s'",
                updatedService.getName(), service.getArea().getName());
        activityLog.createLog(landlord, "UPDATE_AREA_SERVICE", "area_services", updatedService.getId(), description);

        // 5. Map sang DTO và trả về
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